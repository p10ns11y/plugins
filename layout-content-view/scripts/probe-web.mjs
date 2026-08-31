#!/usr/bin/env node
import { createRequire } from "node:module";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { collectInPage } from "./adapters/web-dom.mjs";
import { layoutModeFromSize, staticMachine, VIEWPORTS, report } from "./lcv.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const origin = process.env.ORIGIN || process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
const featuresDir = process.env.FEATURES_DIR;
const brave = process.env.BRAVE_BETA_PATH || "/usr/bin/brave-browser-beta";
const onlyPath = process.env.VERIFY_FEATURE;
const stress = process.env.LCV_STRESS === "1";
const outFile = process.env.LCV_OUT;
const viewports = process.env.LCV_VIEWPORT
  ? VIEWPORTS.filter((item) => item.id === process.env.LCV_VIEWPORT)
  : VIEWPORTS;
if (viewports.length === 0) {
  throw new Error(`Unknown LCV_VIEWPORT=${process.env.LCV_VIEWPORT}`);
}

if (!featuresDir) {
  throw new Error("Set FEATURES_DIR to the verify skill features/ directory");
}
if (!existsSync(brave)) {
  throw new Error(`Brave Beta missing at ${brave}. Set BRAVE_BETA_PATH.`);
}

function loadPaths(dir) {
  const entries = [];
  for (const name of readdirSync(dir)) {
    if (name === "README.md" || !name.endsWith(".md")) continue;
    const sourceFile = join(dir, name);
    const text = readFileSync(sourceFile, "utf8");
    const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!match) throw new Error(`${sourceFile} missing YAML frontmatter`);
    const pathLine = match[1]
      .split(/\r?\n/)
      .map((line) => line.trim())
      .find((line) => line.startsWith("path:"));
    if (!pathLine) throw new Error(`${sourceFile} missing path:`);
    const path = pathLine.slice("path:".length).trim();
    if (!path.startsWith("/")) throw new Error(`${sourceFile} path must start with /`);
    entries.push({ path, sourceFile });
  }
  entries.sort((a, b) => a.path.localeCompare(b.path));
  if (onlyPath) return entries.filter((e) => e.path === onlyPath);
  return entries;
}

function loadChromium() {
  const require = createRequire(join(process.cwd(), "package.json"));
  try {
    return require("@playwright/test").chromium;
  } catch {
    return require("playwright").chromium;
  }
}

function visitsFromShot(path, shot) {
  const walk = process.env.LCV_WALK_STATES !== "0";
  const slides = (shot.states || [])
    .filter((state) => String(state).startsWith("slide:"))
    .map((state) => String(state).slice("slide:".length));
  if (walk && path === "/profile" && slides.length > 0) {
    return slides.slice(0, 48).map((cue) => ({
      uiState: `slide:${cue}`,
      path: `/profile?slide=${encodeURIComponent(cue)}`,
    }));
  }
  return [{ uiState: shot.uiState || "", path }];
}

function samplesFromShot(shot, path, vp, uiState) {
  const layoutMode = shot.layoutMode || layoutModeFromSize(vp.w, vp.h);
  const view = { w: shot.view.w, h: shot.view.h };
  const doc = shot.document;
  const tag = `${path}@${vp.id}@${layoutMode.orientation}@${uiState || "idle"}`;
  const samples = [
    {
      id: `${tag}:document`,
      path,
      viewport: vp,
      layoutMode,
      uiState,
      role: "must-show",
      document: doc,
      inner: {
        scrollW: doc.scrollW,
        clientW: doc.clientW,
        scrollH: doc.clientH,
        clientH: doc.clientH,
      },
      viewBefore: view,
      viewAfter: view,
      computed: {},
      landmarks: shot.landmarks,
    },
  ];
  if (shot.fit?.kind === "beat") {
    samples.push({
      id: `${tag}:fit`,
      path,
      viewport: vp,
      layoutMode,
      uiState,
      role: "must-show",
      fit: "beat",
      remaining: shot.fit.remaining,
      contentMin: shot.fit.contentMin,
      fontPx: shot.fit.fontPx,
      document: doc,
      inner: {
        scrollW: shot.fit.contentMin.w,
        clientW: shot.fit.remaining.w,
        scrollH: shot.fit.contentMin.h,
        clientH: shot.fit.remaining.h,
      },
      viewBefore: view,
      viewAfter: view,
      computed: {},
      landmarks: shot.landmarks,
    });
  }
  for (const node of shot.nodes) {
    if (!node.inner) continue;
    samples.push({
      id: `${tag}:${node.id}`,
      path,
      viewport: vp,
      layoutMode,
      uiState,
      role: node.role,
      document: shot.document,
      inner: node.inner,
      viewBefore: view,
      viewAfter: view,
      computed: node.computed,
      landmarks: shot.landmarks,
      occluded: node.occluded,
      ancestorClip: node.ancestorClip,
      linked: node.linked,
      sel: node.sel,
    });
  }
  return samples;
}

const paths = loadPaths(featuresDir);
const chromium = loadChromium();
const browser = await chromium.launch({
  executablePath: brave,
  headless: true,
});
const findings = [];
const errors = [];
const machines = [];

try {
  for (const { path } of paths) {
    for (const vp of viewports) {
      const context = await browser.newContext({
        viewport: { width: vp.w, height: vp.h },
        reducedMotion: "reduce",
      });
      const page = await context.newPage();
      try {
        await page.goto(new URL(path, origin).toString(), {
          waitUntil: "load",
          timeout: 30_000,
        });
        await new Promise((resolve) => setTimeout(resolve, 200));
        const first = await page.evaluate(collectInPage, false);
        machines.push({
          path,
          viewport: vp.id,
          layoutMode: first.layoutMode,
          uiState: first.uiState,
          machine: staticMachine(first.interact || []),
        });
        const visits = visitsFromShot(path, first);
        for (const visit of visits) {
          if (visit.path !== path) {
            await page.goto(new URL(visit.path, origin).toString(), {
              waitUntil: "load",
              timeout: 30_000,
            });
            await new Promise((resolve) => setTimeout(resolve, 150));
          }
          const shot =
            visit.path === path && visit.uiState === (first.uiState || "")
              ? first
              : await page.evaluate(collectInPage, false);
          const samples = samplesFromShot(shot, path, vp, visit.uiState || shot.uiState || "");
          if (stress) {
            const stressed = await page.evaluate(collectInPage, true);
            const after = { w: stressed.view.w, h: stressed.view.h };
            const layoutMode = stressed.layoutMode || layoutModeFromSize(vp.w, vp.h);
            for (const node of stressed.nodes) {
              if (node.role !== "must-show" || !node.inner) continue;
              samples.push({
                id: `${path}@${vp.id}@${layoutMode.orientation}@${visit.uiState}:${node.id}:stress`,
                path,
                viewport: vp,
                layoutMode,
                uiState: visit.uiState,
                role: "must-show",
                document: stressed.document,
                inner: node.inner,
                viewBefore: { w: shot.view.w, h: shot.view.h },
                viewAfter: after,
                computed: node.computed,
                landmarks: stressed.landmarks,
                occluded: node.occluded,
                ancestorClip: node.ancestorClip,
                sel: node.sel,
              });
            }
          }
          findings.push(...report(samples));
        }
      } catch (err) {
        errors.push({ path, viewport: vp.id, error: String(err) });
      } finally {
        await context.close();
      }
    }
  }
} finally {
  await browser.close();
}

const byKind = {};
for (const row of findings) {
  byKind[row.kind] = (byKind[row.kind] || 0) + 1;
}
const summary = {
  origin,
  plugin: here,
  paths: paths.map((p) => p.path),
  viewports: viewports.map((v) => v.id),
  stress,
  machines,
  totals: {
    samples: findings.length,
    fail: findings.filter((f) => f.fail).length,
    info: findings.filter((f) => f.kind === "inner-overflow-preview").length,
    ok: findings.filter((f) => f.kind === "ok").length,
  },
  byKind,
  errors,
  findings: findings.filter((f) => f.kind !== "ok"),
};

const json = JSON.stringify(summary, null, 2);
if (outFile) writeFileSync(outFile, json);
console.log(json);
if (errors.length) process.exitCode = 2;
