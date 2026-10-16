#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

skill="$ROOT/skills/mission-map/SKILL.md"
command grep -q 'tstack-state' "$skill" && ok "names tstack-state" || bad "names tstack-state"
section="$(awk '
  /^## Loop record$/ {p=1; print; next}
  p && /^## / {exit}
  p {print}
' "$skill")"
[[ "$section" == *"Do not link SQLite into Rust or C."* ]] && ok "loop record keeps sqlite out of rust" || bad "loop record sentence"

echo "---"
[[ "$fail" -eq 0 ]] || { echo "$fail failure(s)"; exit 1; }
echo "ALL CHECKS PASSED"
