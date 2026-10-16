#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

for p in plugin.json LICENSE NOTICE.md README.md commands/tomato.md commands/harvest.md commands/replan.md \
  skills/tomato-loop/SKILL.md skills/capture-sweep/SKILL.md skills/harvest/SKILL.md references/map.md; do
  [[ -f "$ROOT/$p" ]] && ok "exists $p" || bad "missing $p"
done

for dep in mission-map intelli-route control-plane pulse-memory steer-log steer-accel concordance trust-stack si michelin-kitchen pstack-map premflow; do
  [[ -f "$REPO/$dep/plugin.json" ]] && ok "dep $dep" || bad "dep missing $dep"
  command grep -q "$dep" "$ROOT/references/map.md" && ok "map $dep" || bad "map lacks $dep"
done

for d in "$ROOT"/skills/*/; do
  [[ -d "$d/references" || -d "$d/scripts" ]] && bad "copied content in $d" || true
  n="$(wc -l < "$d/SKILL.md")"
  [[ "$n" -le 40 ]] && ok "short $(basename "$d")" || bad "long $(basename "$d") $n"
done

python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["name"]=="tstack"' "$ROOT/plugin.json" && ok "plugin.json" || bad "plugin.json"
[[ "$(command grep -c '```mermaid' "$ROOT/README.md")" -eq 1 ]] && ok "one mermaid" || bad "mermaid count"

loop="$(cat "$ROOT/skills/tomato-loop/SKILL.md")"
for s in \
  'premflow pomo' \
  '/focus' \
  'premflow task add' \
  'different model family' \
  'no freeze is in force' \
  'Weekly pruning: drop unused skills. Keep the ones the owner still runs.'
do
  [[ "$loop" == *"$s"* ]] && ok "loop: $s" || bad "loop missing: $s"
done

# Code points only. The private spellings are not written in this file.
spell() {
  local out="" n
  for n in "$@"; do
    out+=$(printf "\\$(printf '%03o' "$n")")
  done
  printf '%s' "$out"
}
check_absent() {
  i=$((i + 1))
  if command grep -R -F -q -e "$1" "$ROOT"; then
    bad "private spelling #$i"
  else
    ok "private spelling #$i absent"
  fi
}
i=0
check_absent "$(spell 80 114 111 112 111 115 97 108 101 115 32 102 114 101 101 122 101)"
check_absent "$(spell 104 105 114 105 110 103 45 115 105 103 110 97 108 115 45 111 110 98 111 97 114 100)"
check_absent "$(spell 106 111 98 45 98 111 117 110 100 97 114 121)"
check_absent "$(spell 104 97 110 100 111 102 102 45 97 114 116 105 102 97 99 116)"
check_absent "$(spell 114 111 117 116 105 110 101 45 97 114 109 105 110 103)"
check_absent "$(spell 110 97 118 105 103 97 116 105 110 103 45 116 114 97 110 115 112 111 114 116 45 117 105)"
for f in stop pause start --stop --start; do
  [[ "$loop" == *"premflow pomo $f"* || "$loop" == *"premflow $f"* ]] && bad "invented premflow $f" || true
done

agent="$(cat "$ROOT"/commands/*.md "$ROOT"/skills/*/SKILL.md "$ROOT/references/map.md")"
for w in 'Lauren Tan' 'Cirillo' 'thecuriousts' 'Copyright'; do
  [[ "$agent" == *"$w"* ]] && bad "attribution in agent body: $w" || ok "no attribution: $w"
done
all="$(cat "$ROOT"/*.md "$ROOT"/plugin.json "$ROOT"/commands/*.md "$ROOT"/skills/*/SKILL.md "$ROOT/references/map.md")"
if echo "$all" | command grep -Eiwq 'AI|demo|gate|/home/|/Users/|mzapan|100\.[0-9]+\.[0-9]+'; then bad "banned word or host"; else ok "clean words"; fi

echo "---"
[[ "$fail" -eq 0 ]] || { echo "$fail failure(s)"; exit 1; }
echo "ALL CHECKS PASSED"
