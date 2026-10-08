#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { mkdtempSync, readdirSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { gunzipSync } from "node:zlib";
import { scoreText } from "./crap-score.mjs";
import { crapRows, gitChangedLines, parseLimitArgs, resolveTargets, sanitize } from "./js-score-lib.mjs";

const cppExt = new Set([".cc", ".cpp", ".cxx", ".hh", ".hpp", ".hxx"]);
const headerExt = new Set([".h", ".hh", ".hpp", ".hxx"]);
const branchKinds = new Set(["IfStmt", "ForStmt", "WhileStmt", "DoStmt", "CaseStmt", "ConditionalOperator", "CXXCatchStmt"]);
const nestedKinds = new Set(["FunctionDecl", "CXXMethodDecl", "CXXConstructorDecl", "CXXDestructorDecl"]);

function isCpp(file) {
  return cppExt.has(path.extname(file));
}

function lineAt(source, offset) {
  if (typeof offset !== "number" || offset < 0) return null;
  const bytes = Buffer.from(source);
  const stop = Math.min(offset, bytes.length);
  let line = 1;
  for (let index = 0; index < stop; index += 1) if (bytes[index] === 10) line += 1;
  return line;
}

function hasBody(node) {
  return (node.inner || []).some((child) => child && child.kind === "CompoundStmt");
}

function complexity(node) {
  let score = 1;
  function visit(current, top) {
    if (!current || typeof current !== "object") return;
    if (!top && nestedKinds.has(current.kind)) return;
    if (!top && branchKinds.has(current.kind)) score += 1;
    if (!top && current.kind === "BinaryOperator" && (current.opcode === "&&" || current.opcode === "||")) score += 1;
    for (const child of current.inner || []) visit(child, false);
  }
  visit(node, true);
  return score;
}

export function functionsFromClang(ast, source) {
  const records = new Map();
  function index(node) {
    if (!node || typeof node !== "object") return;
    if (node.kind === "CXXRecordDecl" && node.name && node.id) records.set(node.id, node.name);
    for (const child of node.inner || []) index(child);
  }
  index(ast);
  const found = [];
  function collect(node) {
    if (!node || typeof node !== "object") return;
    if (nestedKinds.has(node.kind) && !node.isImplicit && node.name && hasBody(node)) {
      const owner = records.get(node.parentDeclContextId);
      const name = owner ? `${owner}.${node.name}` : node.name;
      const start = lineAt(source, node.loc?.offset ?? node.range?.begin?.offset);
      const end = lineAt(source, node.range?.end?.offset);
      if (start && end) found.push({ name, comp: complexity(node), start, end, key: `${name}:${start}` });
    }
    for (const child of node.inner || []) collect(child);
  }
  collect(ast);
  return found;
}

function clangAst(lib, test) {
  const compiler = isCpp(lib) || isCpp(test) ? "clang++" : "clang";
  const args = [];
  if (compiler === "clang++") args.push("-std=c++17");
  args.push("-Xclang", "-ast-dump=json", "-fsyntax-only", lib);
  const run = spawnSync(compiler, args, { encoding: "utf8", timeout: 20000, maxBuffer: 32 * 1024 * 1024 });
  if (run.error?.code === "ENOENT") return { error: `${compiler} missing` };
  if (run.status !== 0) return { error: `${compiler} failed`, detail: run.stderr || run.stdout };
  try {
    return { ast: JSON.parse(run.stdout || "") };
  } catch {
    return { error: `${compiler} failed`, detail: run.stderr || run.stdout };
  }
}

function gcovLines(report, libName) {
  const files = (Array.isArray(report) ? report : [report]).flatMap((item) => item.files ?? []);
  const file = files.find((item) => path.basename(item.file ?? "") === libName);
  if (!file) return null;
  const covered = new Set();
  const tracked = new Set();
  for (const line of file.lines ?? []) {
    tracked.add(line.line_number);
    if ((line.count ?? 0) > 0) covered.add(line.line_number);
  }
  return { covered, tracked };
}

function command(bin, args, extra) {
  return spawnSync(bin, args, { encoding: "utf8", timeout: 20000, ...extra });
}

function runGcov(lib, test) {
  const compiler = isCpp(lib) || isCpp(test) ? "g++" : "gcc";
  const dir = mkdtempSync(path.join(tmpdir(), "crap-c-"));
  const standard = compiler === "g++" ? ["-std=c++17"] : [];
  const flags = [...standard, "-fprofile-arcs", "-ftest-coverage", "-O0", "-g", `-I${path.dirname(lib)}`];
  try {
    const objects = [];
    if (!headerExt.has(path.extname(lib))) {
      const libObj = path.join(dir, "lib.o");
      const built = command(compiler, [...flags, "-c", lib, "-o", libObj]);
      if (built.error?.code === "ENOENT") return { error: `${compiler} missing` };
      if (built.status !== 0) return { error: `${compiler} failed`, detail: built.stderr || built.stdout };
      objects.push(libObj);
    }
    const testObj = path.join(dir, "test.o");
    const testBuilt = command(compiler, [...flags, "-c", test, "-o", testObj]);
    if (testBuilt.error?.code === "ENOENT") return { error: `${compiler} missing` };
    if (testBuilt.status !== 0) return { error: "coverage suite failed", detail: testBuilt.stderr || testBuilt.stdout };
    objects.push(testObj);
    const prog = path.join(dir, "prog");
    const linked = command(compiler, ["-fprofile-arcs", "-ftest-coverage", ...objects, "-o", prog]);
    if (linked.status !== 0) return { error: "coverage suite failed", detail: linked.stderr || linked.stdout };
    const ran = command(prog, []);
    if (ran.status !== 0) return { error: "coverage suite failed", detail: ran.stderr || ran.stdout };
    const covered = command("gcov", ["--json-format", "-o", dir, lib], { cwd: dir });
    if (covered.status !== 0) return { error: "coverage missing", detail: covered.stderr || covered.stdout };
    const reports = [];
    for (const name of readdirSync(dir)) {
      if (!name.endsWith(".gcov.json.gz")) continue;
      reports.push(JSON.parse(gunzipSync(readFileSync(path.join(dir, name)))));
    }
    const lines = gcovLines(reports, path.basename(lib));
    if (!lines) return { error: "lib not measured" };
    return lines;
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
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
  if (!libArg || !testArg) return fail("usage: crap-score-cc.mjs --max 6 lib test");
  const lib = path.resolve(libArg);
  const test = path.resolve(testArg);
  let source = "";
  try {
    source = readFileSync(lib, "utf8");
  } catch {
    return fail(`missing ${lib}`);
  }
  try {
    readFileSync(test);
  } catch {
    return fail(`missing ${test}`);
  }
  const parsed = clangAst(lib, test);
  if (parsed.error) return fail(parsed.error, parsed.detail);
  const functions = functionsFromClang(parsed.ast, source);
  if (!functions.length) return fail(`no functions in ${path.basename(lib)}`);
  const diff = args.gitRange ? gitChangedLines(lib, args.gitRange) : null;
  const resolved = resolveTargets(functions, args.functions, diff, path.basename(lib));
  if (resolved.error) return fail(resolved.error);
  const measured = runGcov(lib, test);
  if (measured.error) return fail(measured.error, measured.detail);
  const rows = crapRows(resolved.targets, buckets(resolved.targets, measured.covered, measured.tracked));
  if (measured.tracked.size === 0) return fail("lib not measured");
  const printed = scoreText({ ...args, scope: resolved.scope, targets: resolved.targets }, rows);
  process.stdout.write(printed.text);
  return printed.code;
}

function buckets(functions, covered, tracked) {
  const map = new Map(functions.map((fn) => [fn.key, { hit: 0, total: 0 }]));
  for (const line of tracked) {
    const containers = functions.filter((fn) => line >= fn.start && line <= fn.end);
    containers.sort((left, right) => left.end - left.start - (right.end - right.start));
    const owner = containers[0];
    if (!owner) continue;
    const bucket = map.get(owner.key);
    bucket.total += 1;
    if (covered.has(line)) bucket.hit += 1;
  }
  return map;
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  process.exit(main());
}
