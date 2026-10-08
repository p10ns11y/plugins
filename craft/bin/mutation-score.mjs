#!/usr/bin/env node
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";
import {
  fileMutants,
  findUp,
  functionComplexity,
  gitChangedLines,
  loadTypeScript,
  parseLimitArgs,
  resolveTargets,
  sanitize,
  scopeLine,
  scoreMutants,
  strykerConfigText,
} from "./js-score-lib.mjs";

function fail(message, detail) {
  process.stderr.write(`${message}\n`);
  if (detail) process.stderr.write(`${sanitize(detail).trim().slice(-2000)}\n`);
  return 2;
}

function shQuote(value) {
  return `'${value.replaceAll("'", `'"'"'`)}'`;
}

export function formatMutation(args, scope, targets, rows, killed, total) {
  const score = total === 0 ? 0 : killed / total;
  const payload = {
    ok: total > 0 && score >= args.limit,
    threshold: args.limit,
    score: Number(score.toFixed(4)),
    killed,
    mutants: total,
    functions: rows,
  };
  if (args.json) return { code: payload.ok ? 0 : 1, text: `${JSON.stringify(payload)}\n` };
  const lines = [scopeLine(scope, targets)];
  for (const row of rows) {
    lines.push(
      row.total === 0
        ? `${row.name}: mutants=0`
        : `${row.name}: mutation_score=${(row.killed / row.total).toFixed(2)} mutants=${row.total} killed=${row.killed}`,
    );
  }
  lines.push(`mutation_score=${score.toFixed(2)} mutants=${total} killed=${killed} threshold=${args.limit}`);
  return { code: payload.ok ? 0 : 1, text: `${lines.join("\n")}\n` };
}

function readReport(file) {
  return JSON.parse(readFileSync(file, "utf8"));
}

function runStryker(root, libRel, testRel) {
  const dir = mkdtempSync(path.join(tmpdir(), "mut-"));
  const reportFile = path.join(dir, "mutation.json");
  const configFile = path.join(dir, "stryker.config.mjs");
  const command = `pnpm exec vitest run --bail=1 ${shQuote(testRel)}`;
  writeFileSync(configFile, strykerConfigText([libRel], command, reportFile));
  const bin = path.join(root, "node_modules", ".bin", "stryker");
  const run = spawnSync(bin, ["run", configFile], { cwd: root, encoding: "utf8", env: process.env });
  return { run, reportFile, dir };
}

function rowsFor(mutants, targets, useRanges) {
  if (!useRanges) {
    const row = scoreMutants(mutants);
    return { rows: [{ name: targets[0]?.fileName ?? "file", ...row }], killed: row.killed, total: row.total };
  }
  const rows = targets.map((fn) => ({ name: fn.name, ...scoreMutants(mutants, fn) }));
  return {
    rows,
    killed: rows.reduce((sum, row) => sum + row.killed, 0),
    total: rows.reduce((sum, row) => sum + row.total, 0),
  };
}

function main() {
  const args = parseLimitArgs(process.argv.slice(2), "--min", 0.95, true);
  if (args.error) return fail(args.error);
  const [libArg, testArg] = args.positionals;
  if (!libArg || (!testArg && !args.report)) return fail("usage: mutation-score.mjs --min 0.95 lib test");
  const lib = path.resolve(libArg);
  try {
    readFileSync(lib);
  } catch {
    return fail(`missing ${lib}`);
  }
  const ts = loadTypeScript(path.dirname(lib));
  if (!ts) return fail("typescript missing");
  const functions = functionComplexity(ts, readFileSync(lib, "utf8"), lib).map((fn) => ({
    ...fn,
    fileName: path.basename(lib),
  }));
  if (!functions.length) return fail(`no functions in ${path.basename(lib)}`);
  const diff = args.gitRange ? gitChangedLines(lib, args.gitRange) : null;
  const resolved = resolveTargets(functions, args.functions, diff, path.basename(lib));
  if (resolved.error) return fail(resolved.error);
  let report;
  let cleanup = null;
  if (args.report) {
    try {
      report = readReport(path.resolve(args.report));
    } catch {
      return fail("mutation report missing");
    }
  } else {
    const root = findUp(path.dirname(lib), "package.json");
    if (!root) return fail(`no package.json above ${path.basename(lib)}`);
    const bin = path.join(root, "node_modules", ".bin", "stryker");
    try {
      readFileSync(bin);
    } catch {
      return fail("stryker missing");
    }
    const test = path.resolve(testArg);
    try {
      readFileSync(test);
    } catch {
      return fail(`missing ${test}`);
    }
    const stryker = runStryker(root, path.relative(root, lib), path.relative(root, test));
    cleanup = stryker.dir;
    try {
      report = readReport(stryker.reportFile);
    } catch {
      const detail = `${stryker.run.stdout ?? ""}\n${stryker.run.stderr ?? ""}`;
      rmSync(stryker.dir, { recursive: true, force: true });
      return fail("mutation report missing", detail);
    }
  }
  if (cleanup) rmSync(cleanup, { recursive: true, force: true });
  const root = findUp(path.dirname(lib), "package.json") ?? path.dirname(lib);
  const mutants = fileMutants(report, lib, path.relative(root, lib));
  if (mutants === null || mutants.length === 0) return fail("no mutants");
  const useRanges = resolved.scope !== "file";
  const summed = rowsFor(mutants, resolved.targets.map((fn) => ({ ...fn, fileName: path.basename(lib) })), useRanges);
  if (!useRanges) {
    const row = scoreMutants(mutants);
    summed.rows = [{ name: path.basename(lib), killed: row.killed, total: row.total }];
    summed.killed = row.killed;
    summed.total = row.total;
  }
  if (summed.total === 0) return fail("no mutants");
  const printed = formatMutation(args, resolved.scope, resolved.targets, summed.rows, summed.killed, summed.total);
  process.stdout.write(printed.text);
  return printed.code;
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  process.exit(main());
}
