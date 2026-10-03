#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  [[ -f "$ROOT/$1" ]] && ok "exists $1" || bad "missing $1"
}

need plugin.json
need LICENSE
need NOTICE.md
need README.md
need commands/craft.md
need agents/craft.md
need skills/craft/SKILL.md
need skills/craft/references/chain.md
need skills/craft/references/thresholds.md
need skills/craft/references/acceptance.md
need skills/craft/evals/evals.json
need bin/crap-score.py
need bin/mutation-score.py
need bin/score_lib.py
need fixtures/bad-split-cov/lib.py
need fixtures/bad-split-cov/test_lib.py
need test/check-scores.sh
need test/check-acceptance-first.sh

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "craft"' && ok "name" || bad "name"
echo "$pj" | grep -q 'work in progress' && ok "plugin cites WIP" || bad "plugin missing WIP"

rule='Acceptance tests come from the spec before any implementation agent runs'
for surface in skills/craft/SKILL.md commands/craft.md agents/craft.md README.md; do
  if grep -Fq "$rule" "$ROOT/$surface" || grep -Fq 'acceptance tests from the spec before any' "$ROOT/$surface"; then
    ok "acceptance-first in $surface"
  else
    bad "acceptance-first missing in $surface"
  fi
done

skill="$(cat "$ROOT/skills/craft/SKILL.md")"
for token in crap_max mutation scout acceptance hardener cleaner; do
  echo "$skill" | grep -q "$token" && ok "field $token" || bad "missing field $token"
done
echo "$skill" | grep -Fq 'work in progress' && ok "skill cites WIP" || bad "skill missing WIP"
echo "$skill" | grep -Fq 'pstack-map' && ok "skill names pstack-map" || bad "skill missing pstack-map"
echo "$skill" | grep -Fq 'trust-stack' && ok "skill names trust-stack" || bad "skill missing trust-stack"
echo "$skill" | grep -Fq 'does not merge' && ok "skill does not merge" || bad "skill merges"
if echo "$skill" | grep -qi '\bgate\b'; then
  bad "skill uses gate"
else
  ok "skill avoids gate"
fi
readme="$(cat "$ROOT/README.md")"
if echo "$readme" | grep -q '163/181'; then
  bad "README cites unmerged trial"
else
  ok "README omits unmerged trial"
fi

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q 'Robert C. Martin' && ok "NOTICE credits Martin" || bad "NOTICE missing Martin"
echo "$notice" | grep -q 'work in progress' && ok "NOTICE cites WIP" || bad "NOTICE missing WIP"
if echo "$notice" | grep -q '163/181'; then
  bad "NOTICE cites unmerged trial"
else
  ok "NOTICE omits unmerged trial"
fi

evals="$(cat "$ROOT/skills/craft/evals/evals.json")"
echo "$evals" | grep -q 'craft-acceptance-before-coder' && ok "eval acceptance case" || bad "eval acceptance case"
echo "$evals" | grep -q 'crap' && ok "eval crap case" || bad "eval crap case"

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
