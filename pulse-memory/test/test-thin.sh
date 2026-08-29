#!/usr/bin/env bash
# Thin plugin: pulse-memory owns skill + optional rhai. No tether, no always-on hooks.
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
need commands/pulse-memory.md
need cursor/commands/pulse-memory.md
need agents/pulse-memory.md
need skills/pulse-memory/SKILL.md
need skills/pulse-memory/references/admissions.md
need skills/pulse-memory/references/store.md
need skills/pulse-memory/references/usecases.md
need .grok/workflows/pulse-memory.rhai
need test/fixtures/thinking.md
need test/fixtures/harness.md

if [[ -d "$ROOT/c" ]]; then bad "c/ present — EVA owns tether"; else ok "no c/"; fi
if [[ -d "$ROOT/hooks" ]] || [[ -f "$ROOT/hooks.json" ]]; then bad "hooks — Winds"; else ok "no hooks"; fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "pulse-memory"' && ok "plugin.json name" || bad "plugin.json name"

sk="$(cat "$ROOT/skills/pulse-memory/SKILL.md")"
echo "$sk" | grep -q '^name: pulse-memory' && ok "skill name" || bad "skill name"
echo "$sk" | grep -qi 'hint tags\|status:' && ok "skill tags" || bad "skill missing tags"
echo "$sk" | grep -qi 'not in the evidence' && ok "skill abstention" || bad "skill missing abstention"
echo "$sk" | grep -qi 'do not.*average\|Never average' && ok "skill no-average" || bad "skill averages"

rh="$(cat "$ROOT/.grok/workflows/pulse-memory.rhai")"
echo "$rh" | grep -q 'name: "pulse-memory"' && ok "rhai meta.name" || bad "rhai meta.name"
echo "$rh" | grep -q 'as_of' && ok "rhai requires as_of" || bad "rhai missing as_of"
echo "$rh" | grep -q 'mode' && ok "rhai mode" || bad "rhai missing mode"
uc="$(cat "$ROOT/skills/pulse-memory/references/usecases.md")"
echo "$uc" | grep -q 'thinking_path' && ok "usecases thinking_path" || bad "usecases missing thinking_path"
echo "$uc" | grep -q 'harness_path' && ok "usecases harness_path" || bad "usecases missing harness_path"
echo "$uc" | grep -q 'as_of' && ok "usecases as_of" || bad "usecases missing as_of"

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
