import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { functionsFromClang } from "../bin/crap-score-cc.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const cli = path.join(here, "../bin/crap-score.mjs");

function has(bin) {
  return spawnSync(bin, ["--version"], { encoding: "utf8" }).status === 0;
}

test("clang ast supplies c and c++ complexity", () => {
  const source = "int plain(int x) { return x; }\nint gate(int x) {\n  if (x > 0 && x < 3) return 1;\n  return 0;\n}\n";
  const ast = {
    inner: [
      {
        id: "box",
        kind: "CXXRecordDecl",
        name: "Box",
      },
      {
        kind: "FunctionDecl",
        name: "plain",
        loc: { offset: 4 },
        range: { end: { offset: 28 } },
        inner: [{ kind: "CompoundStmt" }],
      },
      {
        kind: "FunctionDecl",
        name: "gate",
        loc: { offset: source.indexOf("gate") },
        range: { end: { offset: source.length - 1 } },
        inner: [
          { kind: "CompoundStmt" },
          { kind: "IfStmt", inner: [{ kind: "BinaryOperator", opcode: "&&" }] },
        ],
      },
      {
        kind: "CXXMethodDecl",
        name: "method",
        parentDeclContextId: "box",
        isImplicit: true,
        inner: [{ kind: "CompoundStmt" }],
      },
      {
        kind: "CXXMethodDecl",
        name: "method",
        parentDeclContextId: "box",
        loc: { offset: 0 },
        range: { end: { offset: 10 } },
        inner: [{ kind: "CompoundStmt" }, { kind: "IfStmt" }],
      },
    ],
  };
  const found = Object.fromEntries(functionsFromClang(ast, source).map((fn) => [fn.name, fn.comp]));
  assert.equal(found.plain, 1);
  assert.equal(found.gate, 3);
  assert.equal(found["Box.method"], 2);
  assert.equal(found.method, undefined);
});

test("cli rejects a missing native file", () => {
  const missing = spawnSync(process.execPath, [cli, path.join(here, "missing.rs"), path.join(here, "missing.rs")], {
    encoding: "utf8",
  });
  assert.equal(missing.status, 2);
  assert.match(missing.stderr, /missing /);
});

test("c coverage run scores the touched function", { skip: has("clang") && has("gcc") ? false : "clang or gcc missing" }, () => {
  const dir = mkdtempSync(path.join(tmpdir(), "crap-c-test-"));
  const lib = path.join(dir, "lib.c");
  const testFile = path.join(dir, "test.c");
  writeFileSync(lib, "int plain(int x) { return x; }\nint gate(int x) {\n  if (x > 0 && x < 3) return 1;\n  return 0;\n}\n");
  writeFileSync(testFile, "int plain(int x);\nint gate(int x);\nint main(void) {\n  return plain(1) == 1 && gate(1) == 1 ? 0 : 1;\n}\n");
  const run = spawnSync(process.execPath, [cli, "--max", "6", lib, testFile], { encoding: "utf8" });
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /plain: comp=1 cov=1.00 crap=1.00/);
  assert.match(run.stdout, /gate: comp=3 /);
});

test("c++ coverage run keeps the method name", { skip: has("clang++") && has("g++") ? false : "clang++ or g++ missing" }, () => {
  const dir = mkdtempSync(path.join(tmpdir(), "crap-cpp-test-"));
  const lib = path.join(dir, "lib.cpp");
  const testFile = path.join(dir, "test.cpp");
  writeFileSync(lib, "struct Box { int method(int x); };\nint Box::method(int x) {\n  if (x) return 1;\n  return 0;\n}\n");
  writeFileSync(testFile, "struct Box { int method(int x); };\nint main() {\n  Box box;\n  return box.method(1) == 1 ? 0 : 1;\n}\n");
  const run = spawnSync(process.execPath, [cli, "--max", "6", lib, testFile], { encoding: "utf8" });
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /Box\.method: comp=2 /);
});

test("rust runner scores the library crate", { skip: has("cargo") && has("rustc") ? false : "cargo or rustc missing", timeout: 180000 }, () => {
  const dir = mkdtempSync(path.join(tmpdir(), "crap-rs-test-"));
  const lib = path.join(dir, "sample.rs");
  const testFile = path.join(dir, "test.rs");
  writeFileSync(lib, "pub fn plain(x: i32) -> i32 { x }\npub fn gate(x: i32) -> i32 {\n    if x > 0 && x < 3 { 1 } else { 0 }\n}\n");
  writeFileSync(testFile, "use sample::{gate, plain};\n#[test]\nfn covers() {\n    assert_eq!(plain(1), 1);\n    assert_eq!(gate(1), 1);\n}\n");
  const run = spawnSync(process.execPath, [cli, "--max", "6", lib, testFile], { encoding: "utf8" });
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /plain: comp=1 cov=1.00 crap=1.00/);
  assert.match(run.stdout, /gate: comp=3 /);
});
