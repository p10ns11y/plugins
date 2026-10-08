import { createRequire } from "node:module";
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import path from "node:path";

export const detectedStatus = new Set(["Killed", "Timeout", "RuntimeError"]);
export const countedStatus = new Set(["Killed", "Timeout", "RuntimeError", "Survived", "NoCoverage"]);

const branchKinds = new Set([
  "IfStatement",
  "ForStatement",
  "ForInStatement",
  "ForOfStatement",
  "WhileStatement",
  "DoStatement",
  "CatchClause",
  "ConditionalExpression",
  "CaseClause",
]);

export function crap(comp, cov) {
  return comp ** 2 * (1 - cov) ** 3 + comp;
}

export function findUp(startDir, name) {
  let dir = path.resolve(startDir);
  while (true) {
    if (existsSync(path.join(dir, name))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

export function loadTypeScript(startDir) {
  const visited = [];
  const root = findUp(startDir, path.join("node_modules", "typescript", "package.json"));
  if (root) visited.push(root);
  for (const entry of (process.env.NODE_PATH || "").split(path.delimiter)) {
    if (entry) visited.push(entry);
  }
  for (const dir of visited) {
    const pkg = path.join(dir, "node_modules", "typescript", "package.json");
    const direct = path.join(dir, "typescript", "package.json");
    const hit = existsSync(pkg) ? pkg : existsSync(direct) ? direct : "";
    if (!hit) continue;
    return createRequire(hit)(path.dirname(hit));
  }
  return null;
}

function isFunctionLike(ts, node) {
  return (
    ts.isFunctionDeclaration(node) ||
    ts.isFunctionExpression(node) ||
    ts.isArrowFunction(node) ||
    ts.isMethodDeclaration(node) ||
    ts.isConstructorDeclaration(node) ||
    ts.isGetAccessorDeclaration(node) ||
    ts.isSetAccessorDeclaration(node)
  );
}

function isNamed(ts, node) {
  if (
    ts.isFunctionDeclaration(node) ||
    ts.isMethodDeclaration(node) ||
    ts.isConstructorDeclaration(node) ||
    ts.isGetAccessorDeclaration(node) ||
    ts.isSetAccessorDeclaration(node)
  ) {
    return true;
  }
  const parent = node.parent;
  return Boolean(
    parent &&
      (ts.isVariableDeclaration(parent) || ts.isPropertyAssignment(parent) || ts.isPropertyDeclaration(parent)),
  );
}

function functionName(ts, node, parentName) {
  if (ts.isConstructorDeclaration(node)) return parentName ? `${parentName}.constructor` : "constructor";
  if (
    ts.isFunctionDeclaration(node) ||
    ts.isMethodDeclaration(node) ||
    ts.isGetAccessorDeclaration(node) ||
    ts.isSetAccessorDeclaration(node)
  ) {
    const name = node.name ? node.name.getText() : "anonymous";
    return parentName ? `${parentName}.${name}` : name;
  }
  const parent = node.parent;
  if (parent && ts.isVariableDeclaration(parent) && ts.isIdentifier(parent.name)) {
    return parentName ? `${parentName}.${parent.name.text}` : parent.name.text;
  }
  if (parent && (ts.isPropertyAssignment(parent) || ts.isPropertyDeclaration(parent)) && parent.name) {
    const name = parent.name.getText();
    return parentName ? `${parentName}.${name}` : name;
  }
  return parentName ? `${parentName}.anonymous` : "anonymous";
}

export function cyclomatic(ts, node) {
  let score = 1;
  function visit(current) {
    if (current !== node && isFunctionLike(ts, current)) return;
    if (current !== node) {
      if (branchKinds.has(ts.SyntaxKind[current.kind])) score += 1;
      if (ts.isBinaryExpression(current)) {
        const operator = current.operatorToken.kind;
        if (
          operator === ts.SyntaxKind.AmpersandAmpersandToken ||
          operator === ts.SyntaxKind.BarBarToken ||
          operator === ts.SyntaxKind.QuestionQuestionToken
        ) {
          score += 1;
        }
      }
    }
    ts.forEachChild(current, visit);
  }
  visit(node);
  return score;
}

export function functionComplexity(ts, sourceText, fileName = "sample.ts") {
  const sourceFile = ts.createSourceFile(fileName, sourceText, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS);
  const found = [];
  function walk(node, parentName) {
    if (isFunctionLike(ts, node) && isNamed(ts, node)) {
      const name = functionName(ts, node, parentName);
      const start = sourceFile.getLineAndCharacterOfPosition(node.getStart(sourceFile)).line + 1;
      const end = sourceFile.getLineAndCharacterOfPosition(node.getEnd()).line + 1;
      found.push({ name, comp: cyclomatic(ts, node), start, end, key: `${name}:${start}` });
      ts.forEachChild(node, (child) => walk(child, name));
      return;
    }
    ts.forEachChild(node, (child) => walk(child, parentName));
  }
  walk(sourceFile, "");
  return found;
}

export function parseLimitArgs(argv, flag, fallback, allowReport) {
  const positionals = [];
  let limit = fallback;
  let json = false;
  let functions = null;
  let gitRange = null;
  let report = null;
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--json") json = true;
    else if (arg === flag) limit = Number(argv[(index += 1)]);
    else if (arg === "--functions") functions = argv[(index += 1)] ?? "";
    else if (arg === "--diff") gitRange = argv[(index += 1)];
    else if (arg === "--report" && allowReport) report = argv[(index += 1)];
    else if (arg.startsWith("-")) return { error: `unknown argument ${arg}` };
    else positionals.push(arg);
  }
  if (!Number.isFinite(limit)) return { error: `invalid ${flag}` };
  return { limit, json, functions, gitRange, report, positionals };
}

export function diffChangedLines(text) {
  const lines = new Set();
  let cur = null;
  for (const raw of text.split(/\r?\n/)) {
    if (raw.startsWith("@@")) {
      const match = /\+(\d+)(?:,(\d+))?/.exec(raw);
      const count = match ? Number(match[2] ?? "1") : 0;
      cur = match && count ? Number(match[1]) : null;
      continue;
    }
    if (cur === null || raw.startsWith("+++") || raw.startsWith("---")) continue;
    if (raw.startsWith("+")) lines.add(cur);
    if (raw.startsWith("+") || raw.startsWith(" ")) cur += 1;
  }
  return lines;
}

export function gitChangedLines(lib, gitRange) {
  const proc = spawnSync(
    "git",
    ["-C", path.dirname(lib), "diff", "-U0", gitRange, "--", path.basename(lib)],
    { encoding: "utf8" },
  );
  if (proc.status !== 0) {
    return { error: (proc.stderr || proc.stdout || `git diff failed (${proc.status})`).trim() };
  }
  return { lines: diffChangedLines(proc.stdout || "") };
}

export function functionsForLines(functions, lines) {
  const hit = functions.filter((fn) => [...lines].some((line) => fn.start <= line && line <= fn.end));
  const names = new Set(hit.map((fn) => fn.name));
  return functions.filter(
    (fn) => names.has(fn.name) && ![...names].some((other) => other.startsWith(`${fn.name}.`)),
  );
}

export function resolveTargets(functions, names, diff, fileName) {
  if (names) {
    const wanted = names.split(",").map((name) => name.trim()).filter(Boolean);
    const targets = [];
    const missing = [];
    for (const name of wanted) {
      const exact = functions.filter((fn) => fn.name === name);
      const found = exact.length ? exact : functions.filter((fn) => fn.name.endsWith(`.${name}`));
      if (!found.length) missing.push(name);
      else targets.push(...found);
    }
    if (missing.length) return { error: `unknown functions: ${missing.join(", ")}` };
    return { scope: "functions", targets };
  }
  if (diff) {
    if (diff.error) return { error: diff.error };
    const targets = functionsForLines(functions, diff.lines);
    if (!targets.length) return { error: `no touched functions in ${fileName}` };
    return { scope: "diff", targets };
  }
  return { scope: "file", targets: functions };
}

export function scopeLine(scope, targets) {
  if (scope === "file") return "scope=file";
  const names = [...new Set(targets.map((fn) => fn.name))].sort();
  return `scope=${scope} functions=${names.join(",")}`;
}

export function smallestOwner(functions, line) {
  const containers = functions.filter((fn) => line >= fn.start && line <= fn.end);
  containers.sort((left, right) => left.end - left.start - (right.end - right.start));
  return containers[0];
}

export function statementCoverage(report, libAbs, functions) {
  const entry = Object.values(report).find((item) => path.resolve(String(item.path ?? "")) === libAbs);
  if (!entry) return null;
  const buckets = new Map(functions.map((fn) => [fn.key, { hit: 0, total: 0 }]));
  for (const [id, span] of Object.entries(entry.statementMap ?? {})) {
    const line = span?.start?.line;
    if (typeof line !== "number") continue;
    const owner = smallestOwner(functions, line);
    if (!owner) continue;
    const bucket = buckets.get(owner.key);
    bucket.total += 1;
    if ((entry.s?.[id] ?? 0) > 0) bucket.hit += 1;
  }
  return buckets;
}

export function crapRows(functions, buckets) {
  return functions.map((fn) => {
    const bucket = buckets?.get(fn.key) ?? { hit: 0, total: 0 };
    const cov = bucket.total === 0 ? 0 : bucket.hit / bucket.total;
    return { name: fn.name, comp: fn.comp, cov, crap: crap(fn.comp, cov) };
  });
}

export function fileMutants(report, libAbs, libRel) {
  const entries = report.files ?? {};
  const rel = libRel.replaceAll("\\", "/");
  const key = Object.keys(entries).find((item) => {
    const norm = item.replaceAll("\\", "/");
    return (path.isAbsolute(item) && path.resolve(item) === libAbs) || norm === rel || norm.endsWith(`/${rel}`);
  });
  return key === undefined ? null : (entries[key].mutants ?? []);
}

export function scoreMutants(mutants, range) {
  let killed = 0;
  let total = 0;
  for (const mutant of mutants) {
    const line = mutant?.location?.start?.line;
    if (range && (typeof line !== "number" || line < range.start || line > range.end)) continue;
    if (!countedStatus.has(mutant.status)) continue;
    total += 1;
    if (detectedStatus.has(mutant.status)) killed += 1;
  }
  return { killed, total, score: total === 0 ? null : killed / total };
}

export function vitestArgs(testRel, libRel, outDir) {
  return [
    "exec",
    "vitest",
    "run",
    testRel,
    "--coverage.enabled",
    "true",
    "--coverage.provider",
    "v8",
    "--coverage.reporter",
    "json",
    "--coverage.reportsDirectory",
    outDir,
    "--coverage.include",
    libRel,
  ];
}

export function strykerConfigText(mutate, testCommand, reportFile) {
  return `export default ${JSON.stringify(
    {
      testRunner: "command",
      commandRunner: { command: testCommand },
      mutate,
      coverageAnalysis: "off",
      reporters: ["json"],
      jsonReporter: { fileName: reportFile },
      thresholds: { high: 95, low: 95, break: null },
      cleanTempDir: true,
      symlinkNodeModules: true,
    },
    null,
    2,
  )};\n`;
}

export function sanitize(text) {
  return String(text).replace(/\/(?:home|Users)\/\S+/g, "[path]").replace(/Bearer\s+\S+/gi, "Bearer [redacted]");
}

export function runPnpm(root, args) {
  const pnpm = spawnSync("pnpm", args, { cwd: root, encoding: "utf8", env: process.env });
  if (pnpm.error?.code === "ENOENT") {
    return spawnSync("npx", args.slice(1), { cwd: root, encoding: "utf8", env: process.env });
  }
  return pnpm;
}
