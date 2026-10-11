#!/usr/bin/env node
/**
 * Print the major version of the newest Node.js LTS line (nodejs.org dist index).
 * Use when applying devcontainer-hardened and the repo has no engines.node pin.
 */
const res = await fetch("https://nodejs.org/dist/index.json");
if (!res.ok) {
  console.error(`nodejs.org dist index: HTTP ${res.status}`);
  process.exit(1);
}

const releases = await res.json();
const lts = releases.filter((r) => r.lts).sort((a, b) => b.date.localeCompare(a.date));

const latest = lts[0];
if (!latest) {
  console.error("No LTS releases in nodejs.org index");
  process.exit(1);
}

const major = latest.version.replace(/^v/, "").split(".")[0];
process.stdout.write("LTS major version: " + major + "\n\n");
process.stdout.write("LTS details: " + JSON.stringify(latest) + "\n\n");
