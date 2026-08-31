#!/usr/bin/env node
import { readdirSync, readFileSync, statSync } from "node:fs";
import { extname, join, relative } from "node:path";

const root = process.env.LCV_APP || process.cwd();
const skip = new Set(["node_modules", ".git", "dist", ".next", "coverage", "out"]);

function walk(dir, acc = []) {
  let entries = [];
  try {
    entries = readdirSync(dir);
  } catch {
    return acc;
  }
  for (const name of entries) {
    if (skip.has(name)) continue;
    const full = join(dir, name);
    let st;
    try {
      st = statSync(full);
    } catch {
      continue;
    }
    if (st.isDirectory()) walk(full, acc);
    else if (/\.(tsx|jsx|html)$/.test(extname(name))) acc.push(full);
  }
  return acc;
}

function propose(file, source) {
  const rel = relative(root, file);
  const rows = [];
  if (/<h1[\s>]/.test(source) && !/data-lcv=/.test(source)) {
    rows.push({ file: rel, mark: "data-lcv=must-show", sel: "h1" });
  }
  if (/line-clamp|text-overflow:\s*ellipsis/.test(source) && !/data-lcv="preview"/.test(source)) {
    rows.push({ file: rel, mark: "data-lcv=preview", sel: "ellipsis/line-clamp" });
  }
  if (/<button\b/.test(source) && !/data-lcv-event/.test(source)) {
    rows.push({ file: rel, mark: "data-lcv-event", sel: "button" });
  }
  if (/\bhref=/.test(source) && !/data-lcv-event/.test(source)) {
    rows.push({ file: rel, mark: "data-lcv-event=navigate", sel: "a/href" });
  }
  if (/100dvh|100vh/.test(source) && !/data-lcv-fit/.test(source)) {
    rows.push({ file: rel, mark: "data-lcv-fit=beat", sel: "viewport theater" });
  }
  return rows;
}

const files = walk(root);
const rows = files.flatMap((file) => propose(file, readFileSync(file, "utf8")));
console.log(JSON.stringify({ root, files: files.length, rows }, null, 2));
