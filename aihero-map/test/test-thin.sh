#!/usr/bin/env bash
# Thin map: credits, not an AI Hero fork.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  local p="$1"
  [[ -f "$ROOT/$p" || -d "$ROOT/$p" ]] && ok "exists $p" || bad "missing $p"
}

need plugin.json
need LICENSE
need NOTICE.md
need README.md
need commands/aihero-map.md
need cursor/commands/aihero-map.md
need agents/aihero-map.md
need skills/aihero-map/SKILL.md
need skills/aihero-map/references/map.md

if [[ -d "$ROOT/skills/engineering" ]]; then bad "upstream skills vendored"; else ok "no upstream skill copy"; fi
if find "$ROOT" -name 'SKILL.md' | grep -v 'skills/aihero-map/SKILL.md' | grep -q .; then
  bad "extra SKILL.md"
else
  ok "one map skill"
fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "aihero-map"' && ok "plugin.json name" || bad "plugin.json name"
echo "$pj" | grep -q 'Matt Pocock' && ok "plugin.json credits Matt Pocock" || bad "plugin.json missing credit"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q 'Matt Pocock' && ok "NOTICE: Matt Pocock" || bad "NOTICE missing Matt Pocock"
echo "$notice" | grep -q 'Lauren Tan' && ok "NOTICE: Lauren Tan" || bad "NOTICE missing Lauren Tan"
echo "$notice" | grep -q 'does not copy' && ok "NOTICE: does not copy" || bad "NOTICE should refuse copy"
echo "$notice" | grep -q 'https://www.aihero.dev/skills' && ok "NOTICE: catalog" || bad "NOTICE missing catalog"

readme="$(cat "$ROOT/README.md")"
echo "$readme" | grep -q 'Matt Pocock' && ok "README: Matt Pocock" || bad "README missing Matt Pocock"
echo "$readme" | grep -q 'Lauren Tan' && ok "README: Lauren Tan" || bad "README missing Lauren Tan"
echo "$readme" | grep -q 'aihero.dev/skills' && ok "README: catalog link" || bad "README missing catalog link"

map="$(cat "$ROOT/skills/aihero-map/references/map.md")"
echo "$map" | grep -q 'wayfinder' && ok "map names wayfinder" || bad "map missing wayfinder"
echo "$map" | grep -q 'https://www.aihero.dev/skills-to-spec' && ok "map links to-spec" || bad "map missing to-spec link"
echo "$map" | grep -q 'Stronger claim' && ok "map names the stronger claim" || bad "map missing stronger claim"

skill="$(cat "$ROOT/skills/aihero-map/SKILL.md")"
echo "$skill" | grep -q 'Matt Pocock' && ok "skill credits Matt Pocock" || bad "skill missing credit"
echo "$skill" | grep -q 'do not copy' && ok "skill refuses copy" || bad "skill should refuse copy"

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
