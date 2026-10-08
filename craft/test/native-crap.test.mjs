import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  bucketsFromLines,
  functionsIn,
  gcovFileLines,
  llvmFileLines,
  nativeLanguage,
} from "../bin/native-crap.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const cli = path.join(here, "../bin/crap-score.mjs");

function byName(source, lang) {
  return Object.fromEntries(functionsIn(source, lang).map((fn) => [fn.name, fn.comp]));
}

function has(bin) {
  return spawnSync(bin, ["--version"], { encoding: "utf8" }).status === 0;
}

test("language comes from the library extension", () => {
  assert.equal(nativeLanguage("lib.rs"), "rust");
  assert.equal(nativeLanguage("lib.c"), "c");
  assert.equal(nativeLanguage("lib.cpp"), "cpp");
  assert.equal(nativeLanguage("lib.ts"), "");
});

test("c and c++ complexity ignores nested functions", () => {
  const comp = byName(
    `
int plain(int x) { return x; }
int gate(int x) {
  if (x > 0 && x < 3) return 1;
  return 0;
}
int choice(int x) { return x ? 1 : 0; }
int outer(int x) {
  int inner(int y) { if (y) return 1; return 0; }
  return inner(x);
}
`,
    "c",
  );
  assert.equal(comp.plain, 1);
  assert.equal(comp.gate, 3);
  assert.equal(comp.choice, 2);
  assert.equal(comp.outer, 1);
  assert.equal(comp["outer.inner"], 2);
  const cpp = byName(
    `
struct Box {
  int method(int x) {
    if (x) return 1;
    return 0;
  }
};
int Box::alone(int x) { return x ? 1 : 0; }
`,
    "cpp",
  );
  assert.equal(cpp["Box.method"], 2);
  assert.equal(cpp["Box.alone"], 2);
});

test("rust complexity counts match arms and impl methods", () => {
  const comp = byName(
    `
pub fn plain(x: i32) -> i32 { x }
pub fn gate(x: i32) -> i32 {
    if x > 0 && x < 3 { 1 } else { 0 }
}
pub fn choice(x: i32) -> i32 {
    match x {
        0 => 1,
        _ => 0,
    }
}
fn outer(x: i32) -> i32 {
    fn inner(y: i32) -> i32 { if y > 0 { 1 } else { 0 } }
    inner(x)
}
impl Box {
    fn method(&self, x: i32) -> i32 { if x > 0 { 1 } else { 0 } }
}
`,
    "rust",
  );
  assert.equal(comp.plain, 1);
  assert.equal(comp.gate, 3);
  assert.equal(comp.choice, 3);
  assert.equal(comp.outer, 1);
  assert.equal(comp["outer.inner"], 2);
  assert.equal(comp["Box.method"], 2);
});

test("gcov and llvm line sets feed the same buckets", () => {
  const functions = functionsIn("int plain(int x) { return x; }\nint gate(int x) {\n  if (x) return 1;\n  return 0;\n}\n", "c");
  const gcov = gcovFileLines(
    {
      files: [
        {
          file: "lib.c",
          lines: [
            { line_number: 1, count: 1 },
            { line_number: 2, count: 1 },
            { line_number: 3, count: 1 },
            { line_number: 4, count: 0 },
          ],
        },
      ],
    },
    "lib.c",
  );
  const rows = bucketsFromLines(functions, gcov.covered, gcov.tracked);
  const gate = functions.find((fn) => fn.name === "gate");
  assert.equal(rows.get(gate.key).hit, 2);
  assert.equal(rows.get(gate.key).total, 3);
  const llvm = llvmFileLines(
    {
      data: [
        {
          files: [
            {
              filename: "/tmp/sample.rs",
              segments: [
                [1, 1, 1, true, true, false],
                [2, 1, 0, true, true, false],
              ],
            },
          ],
        },
      ],
    },
    "/tmp/sample.rs",
  );
  assert.equal(llvm.covered.has(1), true);
  assert.equal(llvm.tracked.has(2), true);
  assert.equal(llvm.covered.has(2), false);
});

test("cli rejects a missing native file", () => {
  const missing = spawnSync(process.execPath, [cli, path.join(here, "missing.rs"), path.join(here, "missing.rs")], {
    encoding: "utf8",
  });
  assert.equal(missing.status, 2);
  assert.match(missing.stderr, /missing /);
});

test("c coverage run scores the touched function", { skip: has("gcc") ? false : "gcc missing" }, () => {
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

test("c++ coverage run keeps the method name", { skip: has("g++") ? false : "g++ missing" }, () => {
  const dir = mkdtempSync(path.join(tmpdir(), "crap-cpp-test-"));
  const lib = path.join(dir, "lib.cpp");
  const testFile = path.join(dir, "test.cpp");
  writeFileSync(lib, "struct Box { int method(int x); };\nint Box::method(int x) {\n  if (x) return 1;\n  return 0;\n}\n");
  writeFileSync(testFile, "struct Box { int method(int x); };\nint main() {\n  Box box;\n  return box.method(1) == 1 ? 0 : 1;\n}\n");
  const run = spawnSync(process.execPath, [cli, "--max", "6", lib, testFile], { encoding: "utf8" });
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /Box\.method: comp=2 /);
});

test("rust coverage run scores the library crate", { skip: has("rustc") ? false : "rustc missing" }, () => {
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
