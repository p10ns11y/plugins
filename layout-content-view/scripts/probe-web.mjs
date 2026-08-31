#!/usr/bin/env node
import { createRequire } from "node:module";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { VIEWPORTS, report } from "./lcv.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const origin = process.env.ORIGIN || process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
const featuresDir = process.env.FEATURES_DIR;
const brave = process.env.BRAVE_BETA_PATH || "/usr/bin/brave-browser-beta";
const onlyPath = process.env.VERIFY_FEATURE;
const stress = process.env.LCV_STRESS === "1";
const outFile = process.env.LCV_OUT;

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

function collectInPage(stressMustShow) {
  const boxOf = (el) => {
    if (!el) return null;
    return {
      scrollW: el.scrollWidth,
      scrollH: el.scrollHeight,
      clientW: el.clientWidth,
      clientH: el.clientHeight,
      w: el.getBoundingClientRect().width,
      h: el.getBoundingClientRect().height,
    };
  };
  const computedOf = (el) => {
    const s = getComputedStyle(el);
    return {
      overflow: s.overflow,
      overflowX: s.overflowX,
      overflowY: s.overflowY,
      textOverflow: s.textOverflow,
      lineClamp: s.webkitLineClamp || s.lineClamp,
      webkitLineClamp: s.webkitLineClamp,
    };
  };
  const occluded = (el) => {
    const r = el.getBoundingClientRect();
    if (r.width < 1 || r.height < 1) return false;
    const top = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2);
    return Boolean(top && top !== el && !el.contains(top) && !top.contains(el));
  };
  const landmarks = [];
  if (document.querySelector("main")) landmarks.push({ role: "main" });
  if (document.querySelector("h1")) landmarks.push({ role: "heading" });
  if (document.querySelector("nav")) landmarks.push({ role: "navigation" });
  if (document.querySelector('a[href="#main"], a[href="#content"]')) {
    landmarks.push({ role: "skip" });
  }

  const seen = new Set();
  const nodes = [];
  const pushNode = (id, sel, el, role) => {
    if (!el || seen.has(el)) return;
    seen.add(el);
    if (stressMustShow && role === "must-show") {
      el.textContent = `${"W".repeat(400)} ${el.textContent || ""}`;
    }
    nodes.push({
      id,
      sel,
      role,
      inner: boxOf(el),
      computed: computedOf(el),
      occluded: role === "must-show" ? occluded(el) : false,
    });
  };

  const dialog = document.querySelector("dialog, [role='dialog']");
  const dialogTitle = dialog?.querySelector("h1, h2, [id$='title']");
  if (dialogTitle) {
    pushNode("dialog-title", "dialog heading", dialogTitle, "must-show");
  } else {
    pushNode("h1", "h1", document.querySelector("h1"), "must-show");
  }
  pushNode(
    "pager-label",
    ".profile-deck__pager-label",
    document.querySelector(".profile-deck__pager-label"),
    "must-show"
  );
  for (const el of document.querySelectorAll("[data-lcv]")) {
    const role = el.getAttribute("data-lcv") || "must-show";
    pushNode(el.id || `data-lcv-${nodes.length}`, "[data-lcv]", el, role);
  }
  for (const el of document.querySelectorAll('[class*="line-clamp"]')) {
    pushNode(el.id || `line-clamp-${nodes.length}`, '[class*="line-clamp"]', el, "preview");
  }

  const root = document.documentElement;
  return {
    landmarks,
    document: boxOf(root),
    view: { w: window.innerWidth, h: window.innerHeight },
    nodes,
  };
}

const paths = loadPaths(featuresDir);
const chromium = loadChromium();
const browser = await chromium.launch({
  executablePath: brave,
  headless: true,
});
const findings = [];
const errors = [];

try {
  for (const { path } of paths) {
    for (const vp of VIEWPORTS) {
      const context = await browser.newContext({
        viewport: { width: vp.w, height: vp.h },
        reducedMotion: "reduce",
      });
      const page = await context.newPage();
      const url = new URL(path, origin).toString();
      try {
        await page.goto(url, { waitUntil: "load", timeout: 30_000 });
        await new Promise((resolve) => setTimeout(resolve, 300));
        const shot = await page.evaluate(collectInPage, false);
        const view = { w: shot.view.w, h: shot.view.h };
        const doc = shot.document;
        const samples = [
          {
            id: `${path}@${vp.id}:document`,
            path,
            viewport: vp,
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
        for (const node of shot.nodes) {
          if (!node.inner) continue;
          samples.push({
            id: `${path}@${vp.id}:${node.id}`,
            path,
            viewport: vp,
            role: node.role,
            document: shot.document,
            inner: node.inner,
            viewBefore: view,
            viewAfter: view,
            computed: node.computed,
            landmarks: shot.landmarks,
            occluded: node.occluded,
            sel: node.sel,
          });
        }
        if (stress) {
          const stressed = await page.evaluate(collectInPage, true);
          const after = { w: stressed.view.w, h: stressed.view.h };
          for (const node of stressed.nodes) {
            if (node.role !== "must-show" || !node.inner) continue;
            samples.push({
              id: `${path}@${vp.id}:${node.id}:stress`,
              path,
              viewport: vp,
              role: "must-show",
              document: stressed.document,
              inner: node.inner,
              viewBefore: view,
              viewAfter: after,
              computed: node.computed,
              landmarks: stressed.landmarks,
              occluded: node.occluded,
              sel: node.sel,
            });
          }
        }
        findings.push(...report(samples));
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
  viewports: VIEWPORTS.map((v) => v.id),
  stress,
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
