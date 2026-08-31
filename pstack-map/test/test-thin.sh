#!/usr/bin/env bash
# Thin map: credits, not a pstack fork.
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
need commands/pstack-map.md
need cursor/commands/pstack-map.md
need agents/pstack-map.md
need skills/pstack-map/SKILL.md
need skills/pstack-map/references/map.md

# Must not vendor pstack
if [[ -d "$ROOT/skills/poteto-mode" ]]; then bad "poteto-mode vendored"; else ok "no poteto-mode copy"; fi
if [[ -d "$ROOT/playbooks" ]]; then bad "playbooks/ present"; else ok "no playbooks/"; fi
if find "$ROOT" -type d -name 'principle-*' | grep -q .; then bad "principle-* vendored"; else ok "no principle copies"; fi
if [[ -d "$ROOT/c" ]]; then bad "c/ present"; else ok "no c/"; fi
if find "$ROOT" -name '*.rhai' | grep -q .; then bad ".rhai present"; else ok "no rhai"; fi
if [[ -d "$ROOT/hooks" ]] || [[ -f "$ROOT/hooks.json" ]]; then bad "hooks present"; else ok "no hooks"; fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "pstack-map"' && ok "plugin.json name" || bad "plugin.json name"
echo "$pj" | grep -qi '"bridge"' && bad "plugin.json still says bridge" || ok "plugin.json no bridge"
echo "$pj" | grep -qi 'Lauren Tan\|poteto\|pstack' && ok "plugin.json credits pstack" || bad "plugin.json missing credit"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q 'Lauren Tan' && ok "NOTICE: Lauren Tan" || bad "NOTICE missing Lauren Tan"
echo "$notice" | grep -q 'Copyright (c) 2026 Lauren Tan' && ok "NOTICE: pstack copyright" || bad "NOTICE missing pstack copyright"
echo "$notice" | grep -qi 'does not copy' && ok "NOTICE: does not copy" || bad "NOTICE should refuse copy"

skill="$(cat "$ROOT/skills/pstack-map/SKILL.md")"
echo "$skill" | grep -q 'Lauren Tan' && ok "skill credits" || bad "skill missing credit"
echo "$skill" | grep -qi 'never-block-on-the-human' && ok "skill HITL override named" || bad "skill missing HITL override"
echo "$skill" | grep -qi 'Graphite' && ok "skill skips Graphite" || bad "skill missing Graphite skip"
if echo "$skill" | grep -q 'Prior→Probe→Simulate→Score'; then
  bad "skill inlines EVA"
else
  ok "skill does not inline EVA DAG"
fi
echo "$skill" | grep -qi 'do not copy\|do not paste\|Map; do not copy' && ok "skill forbids copy" || bad "skill missing no-copy"

cmd="$(cat "$ROOT/commands/pstack-map.md")"
echo "$cmd" | grep -qi 'Lauren Tan' && ok "command credits" || bad "command missing credit"
echo "$cmd" | grep -qi 'do not copy' && ok "command no-copy" || bad "command missing no-copy"
echo "$cmd" | grep -q '\*\*credit\*\*' && ok "command emit credit row" || bad "command missing credit row"

agent="$(cat "$ROOT/agents/pstack-map.md")"
echo "$agent" | grep -qi 'not a pstack fork' && ok "agent: not a fork" || bad "agent missing not-a-fork"
echo "$agent" | grep -c '^---' | grep -q '[1-9]' && ok "agent frontmatter" || bad "agent frontmatter"

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
