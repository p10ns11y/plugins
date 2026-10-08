import { existsSync } from "node:fs";

export function chooseProbeBrowser(env = process.env) {
  const braveBetaPath = env.BRAVE_BETA_PATH;
  if (braveBetaPath) {
    if (!existsSync(braveBetaPath)) {
      throw new Error(`Brave Beta missing at ${braveBetaPath}. Set BRAVE_BETA_PATH.`);
    }
    return { browser: "brave", executablePath: braveBetaPath };
  }

  const chromiumPath = env.CHROMIUM_PATH;
  if (chromiumPath) {
    if (!existsSync(chromiumPath)) {
      throw new Error(`Chromium missing at ${chromiumPath}. Set CHROMIUM_PATH.`);
    }
    return { browser: "chromium", executablePath: chromiumPath };
  }

  return { browser: "playwright" };
}
