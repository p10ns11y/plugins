import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  crap,
  crapRows,
  diffChangedLines,
  fileMutants,
  functionComplexity,
  loadTypeScript,
  scoreMutants,
  statementCoverage,
  strykerConfigText,
  vitestArgs,
} from "../bin/js-score-lib.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const ts = loadTypeScript(here);

test("crap matches the python formula", () => {
  assert.equal(crap(1, 1), 1);
  assert.equal(crap(4, 0), 20);
});

test("typescript parser is available", () => {
  assert.ok(ts, "typescript missing");
});

test("cyclomatic ignores nested functions and counts branches", () => {
  const source = [
    "export function plain() {",
    "  return 1;",
    "}",
    "export function gate(n) {",
    "  if (n > 0 && n < 3) return n;",
    "  return 0;",
    "}",
    "export function choice(n) {",
    "  return n > 0 ? n : 0;",
    "}",
    "export function outer() {",
    "  function inner() {",
    "    if (true) return 1;",
    "  }",
    "  return inner;",
    "}",
  ].join("\n");
  const found = functionComplexity(ts, source, "sample.ts");
  const comp = Object.fromEntries(found.map((fn) => [fn.name, fn.comp]));
  assert.equal(comp.plain, 1);
  assert.equal(comp.gate, 3);
  assert.equal(comp.choice, 2);
  assert.equal(comp.outer, 1);
  assert.equal(comp["outer.inner"], 2);
});

test("statement coverage and diff hunks", () => {
  const functions = functionComplexity(ts, "export function keep() {\n  return 1;\n}\n", "lib.ts");
  const keep = functions[0];
  const report = {
    "/proj/lib.ts": {
      path: "/proj/lib.ts",
      statementMap: { 0: { start: { line: keep.start } } },
      s: { 0: 1 },
    },
  };
  const buckets = statementCoverage(report, "/proj/lib.ts", functions);
  const [row] = crapRows(functions, buckets);
  assert.equal(row.cov, 1);
  assert.equal(row.crap, 1);
  const lines = diffChangedLines("@@ -1 +4,2 @@\n+    return n\n+    return n + 0\n");
  assert.deepEqual([...lines], [4, 5]);
});

test("stryker statuses and config", () => {
  const mutants = [
    { status: "Killed", location: { start: { line: 2 } } },
    { status: "Survived", location: { start: { line: 3 } } },
    { status: "Ignored", location: { start: { line: 2 } } },
    { status: "NoCoverage", location: { start: { line: 8 } } },
  ];
  assert.deepEqual(scoreMutants(mutants, { start: 1, end: 4 }), { killed: 1, total: 2, score: 0.5 });
  const report = { files: { "lib.ts": { mutants } } };
  assert.equal(fileMutants(report, "/proj/lib.ts", "lib.ts").length, 4);
  const text = strykerConfigText(["src/lib.ts"], "pnpm exec vitest run src/lib.test.ts", "/tmp/mutation.json");
  assert.match(text, /"break": null/);
  assert.deepEqual(vitestArgs("test.ts", "lib.ts", "/tmp/cov").slice(0, 4), ["exec", "vitest", "run", "test.ts"]);
});

test("cli rejects a missing file and an unknown function", () => {
  const dir = mkdtempSync(path.join(tmpdir(), "craft-js-"));
  const lib = path.join(dir, "lib.ts");
  writeFileSync(lib, "export function keep() {\n  return 1;\n}\n");
  const missing = spawnSync(process.execPath, [path.join(here, "../bin/crap-score.mjs"), path.join(dir, "nope.ts"), lib], {
    encoding: "utf8",
  });
  assert.equal(missing.status, 2);
  assert.match(missing.stderr, /missing /);
  const unknown = spawnSync(
    process.execPath,
    [path.join(here, "../bin/crap-score.mjs"), "--functions", "nope", lib, lib],
    { encoding: "utf8" },
  );
  assert.equal(unknown.status, 2);
  assert.match(unknown.stderr, /unknown functions: nope/);
});

test("cli scores a saved stryker report", () => {
  const dir = mkdtempSync(path.join(tmpdir(), "craft-mut-"));
  const lib = path.join(dir, "lib.ts");
  const report = path.join(dir, "mutation.json");
  writeFileSync(lib, "export function keep() {\n  return 1;\n}\n");
  writeFileSync(
    report,
    JSON.stringify({
      files: {
        "lib.ts": {
          mutants: [
            { status: "Killed", location: { start: { line: 2 } } },
            { status: "Killed", location: { start: { line: 2 } } },
          ],
        },
      },
    }),
  );
  const run = spawnSync(
    process.execPath,
    [path.join(here, "../bin/mutation-score.mjs"), "--min", "0.95", "--report", report, lib],
    { encoding: "utf8" },
  );
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /scope=file/);
  assert.match(run.stdout, /mutation_score=1.00 mutants=2 killed=2/);
});
