import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { chooseProbeBrowser } from "../scripts/browser-path.mjs";

function withTempBinary(fileName, checkBinary) {
  const directory = mkdtempSync(join(tmpdir(), "lcv-browser-path-"));
  const binaryPath = join(directory, fileName);
  writeFileSync(binaryPath, "");
  try {
    return checkBinary(binaryPath);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

test("no env returns playwright and no executablePath", () => {
  const choice = chooseProbeBrowser({});
  assert.equal(choice.browser, "playwright");
  assert.equal(choice.executablePath, undefined);
});

test("CHROMIUM_PATH pointing at a real temp file returns chromium and that path", () => {
  withTempBinary("chromium", (chromiumPath) => {
    const choice = chooseProbeBrowser({ CHROMIUM_PATH: chromiumPath });
    assert.equal(choice.browser, "chromium");
    assert.equal(choice.executablePath, chromiumPath);
  });
});

test("BRAVE_BETA_PATH wins over CHROMIUM_PATH", () => {
  withTempBinary("brave", (braveBetaPath) => {
    withTempBinary("chromium", (chromiumPath) => {
      const choice = chooseProbeBrowser({
        BRAVE_BETA_PATH: braveBetaPath,
        CHROMIUM_PATH: chromiumPath,
      });
      assert.equal(choice.browser, "brave");
      assert.equal(choice.executablePath, braveBetaPath);
    });
  });
});

test("a set path that does not exist throws", () => {
  const missingBrave = join(tmpdir(), "lcv-missing-brave-beta");
  const missingChromium = join(tmpdir(), "lcv-missing-chromium");
  assert.throws(
    () => chooseProbeBrowser({ BRAVE_BETA_PATH: missingBrave }),
    new Error(`Brave Beta missing at ${missingBrave}. Set BRAVE_BETA_PATH.`)
  );
  assert.throws(
    () => chooseProbeBrowser({ CHROMIUM_PATH: missingChromium }),
    new Error(`Chromium missing at ${missingChromium}. Set CHROMIUM_PATH.`)
  );
});
