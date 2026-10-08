import { spawnSync } from "node:child_process";
import { mkdtempSync, readdirSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { gunzipSync } from "node:zlib";
import { crapRows, gitChangedLines, resolveTargets, sanitize, smallestOwner } from "./js-score-lib.mjs";

const controlNames = new Set(["if", "for", "while", "switch", "catch", "else", "do"]);
const typeIntros = new Set(["struct", "class", "union", "namespace"]);
const trailers = new Set(["const", "volatile", "override", "final", "noexcept", "mutable", "throw"]);
const cBranch = new Set(["if", "for", "while", "case", "catch"]);
const rustBranch = new Set(["if", "for", "while", "loop"]);
const cppExt = new Set([".cc", ".cpp", ".cxx", ".hh", ".hpp", ".hxx"]);
const cExt = new Set([".c", ".h"]);
const headerExt = new Set([".h", ".hh", ".hpp", ".hxx"]);

export function nativeLanguage(file) {
  const ext = path.extname(file);
  if (ext === ".rs") return "rust";
  if (cppExt.has(ext)) return "cpp";
  if (cExt.has(ext)) return "c";
  return "";
}

function isIdentStart(char) {
  return /[A-Za-z_]/.test(char);
}

function isIdentPart(char) {
  return /[A-Za-z0-9_]/.test(char);
}

export function scanTokens(source) {
  const tokens = [];
  let index = 0;
  let line = 1;
  let lineStart = true;
  const push = (text, kind = text) => {
    tokens.push({ text, kind, line });
    lineStart = false;
  };
  while (index < source.length) {
    const char = source[index];
    const next = source[index + 1];
    if (char === "\n") {
      line += 1;
      index += 1;
      lineStart = true;
      continue;
    }
    if (char === " " || char === "\t" || char === "\r") {
      index += 1;
      continue;
    }
    if (char === "#" && lineStart) {
      while (index < source.length && source[index] !== "\n") index += 1;
      continue;
    }
    if (char === "/" && next === "/") {
      while (index < source.length && source[index] !== "\n") index += 1;
      continue;
    }
    if (char === "/" && next === "*") {
      index += 2;
      while (index < source.length && !(source[index] === "*" && source[index + 1] === "/")) {
        if (source[index] === "\n") line += 1;
        index += 1;
      }
      index += 2;
      lineStart = false;
      continue;
    }
    if (char === "R" && next === '"') {
      const delimEnd = source.indexOf("(", index + 2);
      if (delimEnd !== -1) {
        const delim = source.slice(index + 2, delimEnd);
        const close = `)${delim}"`;
        const end = source.indexOf(close, delimEnd + 1);
        const stop = end === -1 ? source.length : end + close.length;
        while (index < stop) {
          if (source[index] === "\n") line += 1;
          index += 1;
        }
        lineStart = false;
        continue;
      }
    }
    if ((char === "r" || char === "b") && (next === '"' || next === "#")) {
      let hashes = 0;
      let cursor = char === "b" && next === "r" ? index + 2 : index + 1;
      if (source[cursor - 1] === "r" || char === "r") {
        while (source[cursor] === "#") {
          hashes += 1;
          cursor += 1;
        }
        if (source[cursor] === '"') {
          const close = `"${"#".repeat(hashes)}`;
          const end = source.indexOf(close, cursor + 1);
          const stop = end === -1 ? source.length : end + close.length;
          while (index < stop) {
            if (source[index] === "\n") line += 1;
            index += 1;
          }
          lineStart = false;
          continue;
        }
      }
    }
    if (char === "'" && isIdentStart(next)) {
      index += 2;
      while (isIdentPart(source[index])) index += 1;
      lineStart = false;
      continue;
    }
    if (char === '"' || char === "'") {
      const quote = char;
      index += 1;
      while (index < source.length && source[index] !== quote) {
        if (source[index] === "\\") index += 1;
        else if (source[index] === "\n") line += 1;
        index += 1;
      }
      index += 1;
      lineStart = false;
      continue;
    }
    if (isIdentStart(char)) {
      const start = index;
      index += 1;
      while (isIdentPart(source[index])) index += 1;
      push(source.slice(start, index), "id");
      continue;
    }
    const two = source.slice(index, index + 2);
    if (two === "&&" || two === "||" || two === "=>" || two === "::" || two === "->") {
      push(two, "op");
      index += 2;
      continue;
    }
    if ("(){}[]<>?:;,".includes(char)) {
      push(char);
      index += 1;
      continue;
    }
    index += 1;
    lineStart = false;
  }
  return tokens;
}

function matchingOpen(tokens, closeIndex) {
  let depth = 1;
  for (let index = closeIndex - 1; index >= 0; index -= 1) {
    if (tokens[index].text === ")") depth += 1;
    else if (tokens[index].text === "(") {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return -1;
}

function functionOpen(tokens, braceIndex) {
  let index = braceIndex - 1;
  while (index >= 0 && (trailers.has(tokens[index].text) || tokens[index].text === "&&")) index -= 1;
  while (index >= 0 && tokens[index].text === ")") {
    const open = matchingOpen(tokens, index);
    const word = tokens[open - 1];
    if (open >= 0 && word && trailers.has(word.text)) {
      index = open - 2;
      continue;
    }
    break;
  }
  if (tokens[index]?.text !== ")") return null;
  const open = matchingOpen(tokens, index);
  if (open < 0) return null;
  const parts = [];
  let cursor = open - 1;
  while (cursor >= 0) {
    const token = tokens[cursor];
    if (token.kind !== "id") break;
    parts.push(token.text);
    const prev = tokens[cursor - 1];
    if (prev?.text === "::") {
      parts.push(".");
      cursor -= 2;
      continue;
    }
    if (prev?.text === "~") {
      parts.push("~");
      cursor -= 2;
    }
    break;
  }
  if (!parts.length) return null;
  const name = parts.reverse().join("");
  if (controlNames.has(name)) return null;
  return { name, line: tokens[open - 1].line };
}

function typeNameBefore(tokens, braceIndex) {
  const parts = [];
  for (let index = braceIndex - 1; index >= 0; index -= 1) {
    const token = tokens[index];
    if (typeIntros.has(token.text)) return parts.reverse().join("");
    if (token.kind === "id") parts.push(token.text);
    else if (token.text === "::") parts.push(".");
    else break;
  }
  return "";
}

function rustImplName(tokens, implIndex) {
  let name = "";
  let sawFor = false;
  let angle = 0;
  for (let index = implIndex + 1; index < tokens.length; index += 1) {
    const token = tokens[index];
    if (token.text === "{") break;
    if (token.text === "<") angle += 1;
    else if (token.text === ">") angle = Math.max(0, angle - 1);
    else if (angle === 0 && token.text === "for") {
      sawFor = true;
      name = "";
    } else if (angle === 0 && token.kind === "id" && !["where", "const", "mut", "dyn", "impl"].includes(token.text)) {
      if (!name || sawFor) {
        name = token.text;
        sawFor = false;
      }
    }
  }
  return name;
}

export function functionsIn(source, lang) {
  const tokens = scanTokens(source);
  const found = [];
  const open = [];
  const types = [];
  let depth = 0;
  let pending = null;
  for (let index = 0; index < tokens.length; index += 1) {
    const token = tokens[index];
    if (lang === "rust" && token.text === "fn" && tokens[index + 1]?.kind === "id") {
      const plain = tokens[index + 1].text;
      const fnOwner = open.at(-1)?.name;
      const typeOwner = types.at(-1)?.name;
      const name = fnOwner ? `${fnOwner}.${plain}` : typeOwner ? `${typeOwner}.${plain}` : plain;
      pending = { name, line: tokens[index + 1].line };
      continue;
    }
    if (lang === "rust" && token.text === "impl" && open.length === 0) {
      const name = rustImplName(tokens, index);
      if (name) pending = { impl: name };
      continue;
    }
    if (token.text === ";" && pending && !pending.impl) pending = null;
    if (token.text === "{") {
      depth += 1;
      if (lang === "rust" && pending?.impl) {
        types.push({ name: pending.impl, depth });
        pending = null;
      } else if (lang === "rust" && pending?.name) {
        open.push({ ...pending, depth, bodyStart: index });
        pending = null;
      } else if (lang !== "rust") {
        const fn = functionOpen(tokens, index);
        if (fn) {
          const prefix = types.map((item) => item.name).filter(Boolean).join(".");
          const qualified = prefix && !fn.name.includes(".") ? `${prefix}.${fn.name}` : fn.name;
          const fnOwner = open.at(-1)?.name;
          const name = fnOwner && !qualified.startsWith(`${fnOwner}.`) ? `${fnOwner}.${qualified}` : qualified;
          open.push({ name, line: fn.line, depth, bodyStart: index });
        } else {
          const typeName = typeNameBefore(tokens, index);
          if (typeName) types.push({ name: typeName, depth });
        }
      }
      continue;
    }
    if (token.text === "}") {
      if (open.at(-1)?.depth === depth) {
        const fn = open.pop();
        found.push({ ...fn, bodyEnd: index, end: token.line });
      }
      if (types.at(-1)?.depth === depth) types.pop();
      depth -= 1;
    }
  }
  return found.map((fn) => ({
    name: fn.name,
    start: fn.line,
    end: fn.end,
    bodyStart: fn.bodyStart,
    bodyEnd: fn.bodyEnd,
    comp: complexity(tokens, fn, found, lang),
    key: `${fn.name}:${fn.line}`,
  }));
}

function complexity(tokens, fn, all, lang) {
  const branches = lang === "rust" ? rustBranch : cBranch;
  const children = all.filter((other) => other.bodyStart > fn.bodyStart && other.bodyEnd < fn.bodyEnd);
  let score = 1;
  for (let index = fn.bodyStart + 1; index < fn.bodyEnd; index += 1) {
    if (children.some((child) => index >= child.bodyStart && index <= child.bodyEnd)) continue;
    const text = tokens[index].text;
    if (branches.has(text) || text === "&&" || text === "||") score += 1;
    if (lang !== "rust" && text === "?") score += 1;
    if (lang === "rust" && text === "=>") score += 1;
  }
  return score;
}

export function bucketsFromLines(functions, covered, tracked) {
  const buckets = new Map(functions.map((fn) => [fn.key, { hit: 0, total: 0 }]));
  for (const line of tracked) {
    const owner = smallestOwner(functions, line);
    if (!owner) continue;
    const bucket = buckets.get(owner.key);
    bucket.total += 1;
    if (covered.has(line)) bucket.hit += 1;
  }
  return buckets;
}

export function gcovFileLines(report, libName) {
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

export function llvmFileLines(report, libAbs) {
  const files = report.data?.[0]?.files ?? [];
  const file = files.find(
    (item) => path.resolve(item.filename ?? "") === libAbs || path.basename(item.filename ?? "") === path.basename(libAbs),
  );
  if (!file) return null;
  const counts = new Map();
  for (const segment of file.segments ?? []) {
    const [line, , count, hasCount] = segment;
    if (!hasCount || typeof line !== "number") continue;
    counts.set(line, Math.max(counts.get(line) ?? 0, count));
  }
  const covered = new Set();
  const tracked = new Set([...counts.keys()]);
  for (const [line, count] of counts) if (count > 0) covered.add(line);
  return { covered, tracked };
}

function command(bin, args, extra) {
  return spawnSync(bin, args, { encoding: "utf8", timeout: 20000, ...extra });
}

function failed(proc, label) {
  if (proc.error?.code === "ENOENT") return `${label} missing`;
  if (proc.status === 0) return "";
  return `${label} failed`;
}

function readGcov(dir) {
  const reports = [];
  for (const name of readdirSync(dir)) {
    if (!name.endsWith(".gcov.json.gz")) continue;
    reports.push(JSON.parse(gunzipSync(readFileSync(path.join(dir, name)))));
  }
  return reports;
}

function runGcov(lib, test) {
  const lang = nativeLanguage(lib);
  const compiler = lang === "cpp" || nativeLanguage(test) === "cpp" ? "g++" : "gcc";
  const dir = mkdtempSync(path.join(tmpdir(), "crap-c-"));
  const standard = compiler === "g++" ? ["-std=c++17"] : [];
  const flags = [compiler, ...standard, "-fprofile-arcs", "-ftest-coverage", "-O0", "-g", `-I${path.dirname(lib)}`];
  try {
    const objects = [];
    if (!headerExt.has(path.extname(lib))) {
      const libObj = path.join(dir, "lib.o");
      const built = command(compiler, [...flags.slice(1), "-c", lib, "-o", libObj]);
      const error = failed(built, compiler);
      if (error) return { error, detail: built.stderr || built.stdout };
      objects.push(libObj);
    }
    const testObj = path.join(dir, "test.o");
    const testBuilt = command(compiler, [...flags.slice(1), "-c", test, "-o", testObj]);
    const testError = failed(testBuilt, compiler);
    if (testError) return { error: testError, detail: testBuilt.stderr || testBuilt.stdout };
    objects.push(testObj);
    const prog = path.join(dir, "prog");
    const linked = command(compiler, ["-fprofile-arcs", "-ftest-coverage", ...objects, "-o", prog]);
    if (linked.status !== 0) return { error: "coverage suite failed", detail: linked.stderr || linked.stdout };
    const ran = command(prog, []);
    if (ran.status !== 0) return { error: "coverage suite failed", detail: ran.stderr || ran.stdout };
    const covered = command("gcov", ["--json-format", "-o", dir, lib], { cwd: dir });
    if (covered.status !== 0) return { error: "coverage missing", detail: covered.stderr || covered.stdout };
    const lines = gcovFileLines(readGcov(dir), path.basename(lib));
    if (!lines) return { error: "lib not measured" };
    return lines;
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

function llvmBinaries() {
  const info = command("rustc", ["-vV"]);
  if (info.status !== 0) return { error: failed(info, "rustc") || "rustc missing" };
  const sysroot = command("rustc", ["--print", "sysroot"]);
  const host = /^host: (.+)$/m.exec(info.stdout || "")?.[1];
  const root = (sysroot.stdout || "").trim();
  if (!host || !root) return { error: "llvm-cov missing" };
  const bin = path.join(root, "lib", "rustlib", host, "bin");
  return { cov: path.join(bin, "llvm-cov"), prof: path.join(bin, "llvm-profdata") };
}

function runRust(lib, test) {
  const tools = llvmBinaries();
  if (tools.error) return tools;
  const dir = mkdtempSync(path.join(tmpdir(), "crap-rs-"));
  const stem = path.basename(lib, ".rs").replaceAll("-", "_");
  const rlib = path.join(dir, `lib${stem}.rlib`);
  const prog = path.join(dir, "prog");
  try {
    const libBuilt = command("rustc", [
      "-C",
      "instrument-coverage",
      "--edition",
      "2021",
      "--crate-name",
      stem,
      "--crate-type",
      "rlib",
      lib,
      "-o",
      rlib,
    ]);
    const libError = failed(libBuilt, "rustc");
    if (libError) return { error: libError, detail: libBuilt.stderr || libBuilt.stdout };
    const testBuilt = command("rustc", [
      "-C",
      "instrument-coverage",
      "--edition",
      "2021",
      "--test",
      test,
      "--extern",
      `${stem}=${rlib}`,
      "-o",
      prog,
    ]);
    if (testBuilt.status !== 0) return { error: "coverage suite failed", detail: testBuilt.stderr || testBuilt.stdout };
    const ran = command(prog, [], { env: { ...process.env, LLVM_PROFILE_FILE: path.join(dir, "prof_%p.profraw") } });
    if (ran.status !== 0) return { error: "coverage suite failed", detail: ran.stderr || ran.stdout };
    const merged = command(tools.prof, ["merge", "-sparse", "-o", path.join(dir, "prof.data"), ...readdirSync(dir).filter((name) => name.endsWith(".profraw")).map((name) => path.join(dir, name))]);
    if (merged.status !== 0) return { error: "coverage missing", detail: merged.stderr || merged.stdout };
    const exported = command(tools.cov, ["export", "-format=text", `-instr-profile=${path.join(dir, "prof.data")}`, prog]);
    if (exported.status !== 0) return { error: "coverage missing", detail: exported.stderr || exported.stdout };
    const lines = llvmFileLines(JSON.parse(exported.stdout || "{}"), path.resolve(lib));
    if (!lines) return { error: "lib not measured" };
    return lines;
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

export function scoreNative(lib, test, args) {
  const lang = nativeLanguage(lib);
  if (!lang) return { error: `unsupported ${path.extname(lib)}` };
  let source = "";
  try {
    source = readFileSync(lib, "utf8");
  } catch {
    return { error: `missing ${lib}` };
  }
  const functions = functionsIn(source, lang);
  if (!functions.length) return { error: `no functions in ${path.basename(lib)}` };
  const diff = args.gitRange ? gitChangedLines(lib, args.gitRange) : null;
  const resolved = resolveTargets(functions, args.functions, diff, path.basename(lib));
  if (resolved.error) return { error: resolved.error };
  try {
    readFileSync(test);
  } catch {
    return { error: `missing ${test}` };
  }
  const measured = lang === "rust" ? runRust(lib, test) : runGcov(lib, test);
  if (measured.error) return { error: measured.error, detail: sanitize(measured.detail ?? "") };
  const rows = crapRows(resolved.targets, bucketsFromLines(resolved.targets, measured.covered, measured.tracked));
  if (rows.every((row) => row.cov === 0 && row.comp > 0) && measured.tracked.size === 0) return { error: "lib not measured" };
  return { scope: resolved.scope, targets: resolved.targets, rows };
}
