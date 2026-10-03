#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  [[ -f "$ROOT/$1" || -d "$ROOT/$1" ]] && ok "exists $1" || bad "missing $1"
}

for habit in shared-scripts findings-first events-over-timers workflow-skills no-rule-one-off environment-on-repeat scaled-verifiers kitchen-time; do
  need "skills/$habit/SKILL.md"
  need "commands/$habit.md"
done

need plugin.json
need LICENSE
need NOTICE.md
need README.md
need agents/michelin-kitchen.md
need skills/michelin-kitchen/SKILL.md
need skills/michelin-kitchen/evals/evals.json
need examples/posting-check/README.md

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "michelin-kitchen"' && ok "name" || bad "name"

readme="$(cat "$ROOT/README.md")"
echo "$readme" | grep -q 'Lauren Tan' && ok "readme credits Lauren Tan" || bad "readme missing Lauren Tan"
echo "$readme" | grep -q 'Matt Pocock' && ok "readme credits Matt Pocock" || bad "readme missing Matt Pocock"
echo "$readme" | grep -q 'House adaptation' && ok "readme marks adaptations" || bad "readme missing adaptation label"
echo "$readme" | grep -q 'does not want to sell this' && ok "readme pstack caveat" || bad "readme missing pstack caveat"
echo "$readme" | grep -q 'Own your knives' && ok "readme own knives" || bad "readme missing own knives"
echo "$readme" | grep -q 'Lauren Tan.s Cursor plugin' && ok "readme pstack is Cursor plugin" || bad "readme pstack attribution"
echo "$readme" | grep -q '3 Oct 2026' && ok "readme 3 Oct findings note" || bad "readme missing 3 Oct note"
if echo "$readme" | grep -qi '\bgate\b'; then bad "readme uses gate"; else ok "readme avoids gate"; fi

scaled="$(cat "$ROOT/skills/scaled-verifiers/SKILL.md")"
echo "$scaled" | grep -q 'house adaptation' && ok "scaled-verifiers marked adaptation" || bad "scaled-verifiers not marked"
echo "$scaled" | grep -q 'did not offer a general recipe' && ok "scaled one-way caveat" || bad "scaled missing one-way caveat"

kitchen="$(cat "$ROOT/skills/kitchen-time/SKILL.md")"
echo "$kitchen" | grep -q 'house adaptation' && ok "kitchen-time marked adaptation" || bad "kitchen-time not marked"
if echo "$kitchen" | grep -qi '20%'; then bad "kitchen-time invents slice"; else ok "kitchen-time no fake slice"; fi

oneoff="$(cat "$ROOT/skills/no-rule-one-off/SKILL.md")"
echo "$oneoff" | grep -q 'nothing to fix' && ok "one-off quote" || bad "one-off missing quote"

repeat="$(cat "$ROOT/skills/environment-on-repeat/SKILL.md")"
echo "$repeat" | grep -q 'multiple agents' && ok "repeat needs multiple agents" || bad "repeat missing multi-agent"

findings="$(cat "$ROOT/skills/findings-first/SKILL.md")"
echo "$findings" | grep -q '3 Oct 2026' && ok "findings 3 Oct note" || bad "findings missing 3 Oct"

events="$(cat "$ROOT/skills/events-over-timers/SKILL.md")"
echo "$events" | grep -q 'findings-first' && ok "events links findings buffer" || bad "events missing findings link"

workflow="$(cat "$ROOT/skills/workflow-skills/SKILL.md")"
echo "$workflow" | grep -q 'workflow' && ok "workflow-skills topic" || bad "workflow-skills missing topic"
if echo "$workflow" | grep -q 'github.com/cursor/plugins'; then ok "workflow cites pstack upstream"; else bad "workflow missing pstack link"; fi

scripts="$(cat "$ROOT/skills/shared-scripts/SKILL.md")"
echo "$scripts" | grep -q 'JSON' && ok "shared-scripts JSON" || bad "shared-scripts missing JSON"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q 'house adaptations' && ok "notice adaptations" || bad "notice missing adaptations"
echo "$notice" | grep -q 'trust-stack' && ok "notice overlap trust-stack" || bad "notice missing trust-stack"

evals="$(cat "$ROOT/skills/michelin-kitchen/evals/evals.json")"
echo "$evals" | grep -q 'mk-shared-scripts-repeat' && ok "eval shared-scripts" || bad "eval missing shared-scripts"
echo "$evals" | grep -q 'mk-findings-before-ping' && ok "eval findings" || bad "eval missing findings"
echo "$evals" | grep -q 'mk-scaled-verifiers-adaptation' && ok "eval scaled" || bad "eval missing scaled"

posting="$(cat "$ROOT/examples/posting-check/README.md")"
echo "$posting" | grep -q 'Deterministic' && ok "posting-check example" || bad "posting-check example weak"
if echo "$posting" | grep -q '/workspace'; then bad "posting-check has real path"; else ok "posting-check host-neutral"; fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
