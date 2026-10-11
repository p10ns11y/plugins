#!/usr/bin/env bash
# control-plane: port copy, feeder and graph stay separate, skills-repo URLs stay canonical.
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
need commands/feed.md
need commands/control-graph.md
need skills/control-feeder/SKILL.md
need skills/control-graph/SKILL.md
need skills/higher-order-decision-architect/SKILL.md
need skills/examples/overlays/thepulimaangani-decision-hooks.md
need cursor/rules/clt-dual-load.mdc
need cursor/rules/control-graph.mdc
need cursor/rules/higher-order-decision-architect.mdc

if grep -Fq 'fusion-sage' "$ROOT/skills/higher-order-decision-architect/SKILL.md"; then
  bad "hoda activation still names fusion-sage"
else
  ok "hoda activation uses architecture-synthesis"
fi

mark='Port copy. Canonical file remains in https://github.com/p10ns11y/skills on master.'
for skill in control-feeder control-graph higher-order-decision-architect; do
  if grep -Fq "$mark" "$ROOT/skills/$skill/SKILL.md"; then
    ok "port mark in $skill"
  else
    bad "port mark missing in $skill"
  fi
done

feed="$(cat "$ROOT/commands/feed.md")"
echo "$feed" | grep -Fq 'Load skill **control-feeder**' && ok "feed loads feeder" || bad "feed misses feeder"
echo "$feed" | grep -Fq 'Do not open a control card' && ok "feed skips the card" || bad "feed opens a card"

graph="$(cat "$ROOT/commands/control-graph.md")"
echo "$graph" | grep -Fq 'Load skill **control-graph**' && ok "graph loads graph" || bad "graph misses graph"
echo "$graph" | grep -Fq 'Do not restate control-feeder' && ok "graph skips feeder" || bad "graph restates feeder"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -Fq 'intelli-route' && ok "notice keeps intelli-route on the skills repo" || bad "notice misses intelli-route"
echo "$notice" | grep -Fq 'control-graph/SKILL.md' && ok "notice names canonical graph" || bad "notice misses canonical graph"

if [[ -d "$ROOT/../dependency-harden" || -d "$ROOT/../context-ignite" ]]; then
  bad "later plugins were created in this port"
else
  ok "later plugins absent"
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
