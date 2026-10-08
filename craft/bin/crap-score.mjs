#!/usr/bin/env node
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { nativeLanguage, scoreNative } from "./native-crap.mjs";
import {
  crapRows,
  findUp,
  functionComplexity,
  gitChangedLines,
  loadTypeScript,
  parseLimitArgs,
  resolveTargets,
  runPnpm,
  sanitize,
  scopeLine,
  statementCoverage,
  vitestArgs,
} from "./js-score-lib.mjs";

export function scoreText(args, rows) {
  const worst = rows.reduce((best, row) => (row.crap > best.crap ? row : best), rows[0]);
  const payload = {
    ok: worst !== undefined && worst.crap <= args.limit,
    threshold: args.limit,
    worst: worst ? { name: worst.name, crap: Number(worst.crap.toFixed(2)) } : null,
    functions: rows.map((row) => ({
      name: row.name,
      comp: row.comp,
      cov: Number(row.cov.toFixed(4)),
      crap: Number(row.crap.toFixed(2)),
    })),
  };
  if (args.json) return { code: payload.ok ? 0 : 1, text: `${JSON.stringify(payload)}\n` };
  const lines = [scopeLine(args.scope, args.targets)];
  for (const row of rows) {
    lines.push(`${row.name}: comp=${row.comp} cov=${row.cov.toFixed(2)} crap=${row.crap.toFixed(2)}`);
  }
  lines.push(
    `worst=${worst ? worst.name : ""} crap_max=${worst ? worst.crap.toFixed(2) : "0.00"} threshold=${args.limit}`,
  );
  return { code: payload.ok ? 0 : 1, text: `${lines.join("\n")}\n` };
}

function fail(message, detail) {
  process.stderr.write(`${message}\n`);
  if (detail) process.stderr.write(`${sanitize(detail).trim().slice(-2000)}\n`);
  return 2;
}

function main() {
  const args = parseLimitArgs(process.argv.slice(2), "--max", 6, false);
  if (args.error) return fail(args.error);
  const [libArg, testArg] = args.positionals;
  if (!libArg || !testArg) return fail("usage: crap-score.mjs --max 6 lib test");
  const lib = path.resolve(libArg);
  const test = path.resolve(testArg);
  try {
    readFileSync(lib);
  } catch {
    return fail(`missing ${lib}`);
  }
  if (nativeLanguage(lib)) {
    const native = scoreNative(lib, test, args);
    if (native.error) return fail(native.error, native.detail);
    const printed = scoreText(
      { ...args, scope: native.scope, targets: native.targets },
      native.rows,
    );
    process.stdout.write(printed.text);
    return printed.code;
  }
  const ts = loadTypeScript(path.dirname(lib));
  if (!ts) return fail("typescript missing");
  const functions = functionComplexity(ts, readFileSync(lib, "utf8"), lib);
  if (!functions.length) return fail(`no functions in ${path.basename(lib)}`);
  const diff = args.gitRange ? gitChangedLines(lib, args.gitRange) : null;
  const resolved = resolveTargets(functions, args.functions, diff, path.basename(lib));
  if (resolved.error) return fail(resolved.error);
  try {
    readFileSync(test);
  } catch {
    return fail(`missing ${test}`);
  }
  const root = findUp(path.dirname(lib), "package.json");
  if (!root) return fail(`no package.json above ${path.basename(lib)}`);
  const outDir = mkdtempSync(path.join(tmpdir(), "crap-"));
  const run = runPnpm(root, vitestArgs(path.relative(root, test), path.relative(root, lib), outDir));
  if (run.error?.code === "ENOENT") return fail("vitest missing");
  if (run.status !== 0) {
    rmSync(outDir, { recursive: true, force: true });
    return fail("coverage suite failed", `${run.stdout ?? ""}\n${run.stderr ?? ""}`);
  }
  let report;
  try {
    report = JSON.parse(readFileSync(path.join(outDir, "coverage-final.json"), "utf8"));
  } catch {
    rmSync(outDir, { recursive: true, force: true });
    return fail("coverage missing");
  }
  rmSync(outDir, { recursive: true, force: true });
  const buckets = statementCoverage(report, lib, resolved.targets);
  if (!buckets) return fail("lib not measured");
  const printed = scoreText({ ...args, scope: resolved.scope, targets: resolved.targets }, crapRows(resolved.targets, buckets));
  process.stdout.write(printed.text);
  return printed.code;
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  process.exit(main());
}
