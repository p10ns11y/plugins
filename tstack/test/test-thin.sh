#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

for p in plugin.json LICENSE NOTICE.md README.md commands/tomato.md commands/harvest.md commands/replan.md \
  skills/tomato-loop/SKILL.md skills/capture-sweep/SKILL.md skills/harvest/SKILL.md references/map.md \
  references/cards.md \
  connectors/mail.allow \
  connectors/calendar.allow \
  connectors/chat.allow \
  connectors/pr.allow \
  bin/capture-sweep \
  skills/capture-mail/SKILL.md \
  skills/capture-calendar/SKILL.md \
  skills/capture-chat/SKILL.md \
  skills/capture-pr/SKILL.md \
  test/test-capture.sh \
  test/fixtures/capture/mail-none.txt; do
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
  'tstack/bin/merge-check' \
  'FREEZE' \
  'Weekly pruning: drop unused skills. Keep the ones the owner still runs.'
do
  [[ "$loop" == *"$s"* ]] && ok "loop: $s" || bad "loop missing: $s"
done
[[ "$loop" == *'**concordance** proceeds'* ]] && bad "merge bullet still sends concordance" || ok "merge bullet leaves concordance"

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

for p in references/state.md scripts/schema.sql scripts/tstack-state test/test-state.sh; do
  [[ -f "$ROOT/$p" ]] && ok "exists $p" || bad "missing $p"
done
[[ -x "$ROOT/scripts/tstack-state" ]] && ok "executable tstack-state" || bad "not executable"
harvest="$(cat "$ROOT/skills/harvest/SKILL.md")"
[[ "$harvest" == *tstack-state* ]] && ok "harvest names tstack-state" || bad "harvest tstack-state"
[[ "$loop" == *tstack-state* ]] && ok "tomato names tstack-state" || bad "tomato tstack-state"
[[ "$harvest" == *"premflow win"* ]] && ok "premflow win" || bad "premflow win"
[[ "$harvest" == *"premflow task done"* ]] && ok "premflow task done" || bad "premflow task done"
[[ "$harvest" == *"premflow/README.md"* ]] && ok "premflow readme" || bad "premflow readme"
bash "$ROOT/test/test-state.sh" && ok "test-state" || bad "test-state"

merge="$ROOT/bin/merge-check"
[[ -x "$merge" ]] && ok "executable merge-check" || bad "merge-check not executable"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
errf="$tmp/err"

status=0
out="$("$merge" --repo "$tmp" --tests-exit 0 --writer-family grok --reviewer-family claude 2>"$errf")" || status=$?
err="$(cat "$errf")"
if [[ "$status" -eq 0 && -z "$out" && -z "$err" ]]; then
  ok "merge proceed"
else
  bad "merge proceed status=$status out=$out err=$err"
fi

status=0
out="$("$merge" --repo "$tmp" --tests-exit 1 --writer-family grok --reviewer-family claude 2>"$errf")" || status=$?
if [[ "$status" -eq 1 && "$out" == "hold: tests" ]]; then
  ok "hold tests"
else
  bad "hold tests status=$status out=$out"
fi

status=0
out="$("$merge" --repo "$tmp" --tests-exit 0 --writer-family grok --reviewer-family grok 2>"$errf")" || status=$?
if [[ "$status" -eq 1 && "$out" == "hold: review" ]]; then
  ok "hold review"
else
  bad "hold review status=$status out=$out"
fi

touch "$tmp/FREEZE"
status=0
out="$("$merge" --repo "$tmp" --tests-exit 0 --writer-family grok --reviewer-family claude 2>"$errf")" || status=$?
if [[ "$status" -eq 1 && "$out" == "hold: freeze" ]]; then
  ok "hold freeze"
else
  bad "hold freeze status=$status out=$out"
fi

status=0
out="$("$merge" --repo "$tmp" --tests-exit 0 --writer-family grok 2>"$errf")" || status=$?
if [[ "$status" -eq 1 && "$out" == "hold: args" ]]; then
  ok "hold args"
else
  bad "hold args status=$status out=$out"
fi

agent="$(cat "$ROOT"/commands/*.md "$ROOT"/skills/*/SKILL.md "$ROOT/references/map.md" "$ROOT/references/state.md")"
for w in 'Lauren Tan' 'Cirillo' 'thecuriousts' 'Copyright'; do
  [[ "$agent" == *"$w"* ]] && bad "attribution in agent body: $w" || ok "no attribution: $w"
done
all="$(cat "$ROOT"/*.md "$ROOT"/plugin.json "$ROOT"/commands/*.md "$ROOT"/skills/*/SKILL.md "$ROOT"/references/*.md "$ROOT"/scripts/schema.sql "$ROOT"/scripts/tstack-state "$ROOT"/connectors/*.allow "$ROOT"/bin/capture-sweep "$ROOT"/test/test-capture.sh "$ROOT"/test/fixtures/capture/*.txt)"
if echo "$all" | command grep -Eiwq 'AI|demo|gate|/home/|/Users/|mzapan|100\.[0-9]+\.[0-9]+'; then bad "banned word or host"; else ok "clean words"; fi

sweep="$(cat "$ROOT/skills/capture-sweep/SKILL.md")"
for s in capture-mail capture-calendar capture-pr capture-chat control-plane pulse-memory mission-map michelin-kitchen check-allows; do
  [[ "$sweep" == *"$s"* ]] && ok "sweep $s" || bad "sweep lacks $s"
done
[[ "$sweep" == *'**si**'* ]] && ok "sweep si" || bad "sweep lacks si"
map="$(cat "$ROOT/references/map.md")"
for s in capture-mail capture-calendar capture-pr capture-chat; do
  [[ "$map" == *"$s"* ]] && ok "route $s" || bad "route lacks $s"
done
if command grep -E -q 'gh pr (create|comment|merge|review|close|edit|diff|view)|send_message|create_event|curl |wget ' "$ROOT/bin/capture-sweep"; then
  bad "write command in script"
else
  ok "script reads only"
fi

bash "$ROOT/test/test-capture.sh"

echo "---"
[[ "$fail" -eq 0 ]] || { echo "$fail failure(s)"; exit 1; }
echo "ALL CHECKS PASSED"
