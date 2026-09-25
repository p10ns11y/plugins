#!/usr/bin/env bash
# Composition plugin: references skills and pstack. Does not vendor either.
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
need manifest.json
need AGENTS.md
need commands/intelliarch.md
need cursor/commands/intelliarch.md
need cursor/rules/intelliarch-stack.mdc
need .grok/workflows/intelliarch.rhai
need bot/intelliarch.md
need agents/intelliarch.md

if [[ -d "$ROOT/skills" ]]; then bad "skills/ present (bodies must stay upstream)"; else ok "no skills/ copy"; fi
if [[ -d "$ROOT/skills/poteto-mode" || -d "$ROOT/poteto-mode" ]]; then bad "poteto-mode vendored"; else ok "no poteto-mode copy"; fi
if [[ -d "$ROOT/playbooks" ]]; then bad "playbooks/ present"; else ok "no playbooks/"; fi
if find "$ROOT" -type d -name 'principle-*' | grep -q .; then bad "principle-* vendored"; else ok "no principle copies"; fi
if find "$ROOT" -name 'SKILL.md' | grep -q .; then bad "SKILL.md vendored"; else ok "no SKILL.md"; fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "intelliarch"' && ok "plugin.json name" || bad "plugin.json name"
echo "$pj" | grep -q 'Lauren Tan' && ok "plugin.json credits pstack" || bad "plugin.json missing credit"
echo "$pj" | grep -q 'Does not copy' && ok "plugin.json no-copy" || bad "plugin.json missing no-copy"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q 'Lauren Tan' && ok "NOTICE: Lauren Tan" || bad "NOTICE missing Lauren Tan"
echo "$notice" | grep -q 'does not copy' && ok "NOTICE: does not copy" || bad "NOTICE should refuse copy"
echo "$notice" | grep -q 'github.com/p10ns11y/skills' && ok "NOTICE: skills repo" || bad "NOTICE missing skills repo"

man="$(cat "$ROOT/manifest.json")"
echo "$man" | grep -q 'github.com/p10ns11y/skills' && ok "manifest skills remote" || bad "manifest missing skills remote"
echo "$man" | grep -q 'github.com/cursor/plugins/tree/main/pstack' && ok "manifest pstack upstream" || bad "manifest missing pstack url"
if echo "$man" | grep -q '/agent/'; then bad "manifest has machine path"; else ok "manifest has no machine path"; fi
if echo "$man" | grep -q 'cursor-public'; then bad "manifest has plugin cache path"; else ok "manifest has no cache path"; fi

cmd="$(cat "$ROOT/commands/intelliarch.md")"
echo "$cmd" | grep -q 'Lauren Tan' && ok "command credits" || bad "command missing credit"
echo "$cmd" | grep -qi 'do not copy' && ok "command no-copy" || bad "command missing no-copy"
echo "$cmd" | grep -q 'manifest.json' && ok "command points at manifest" || bad "command missing manifest"

agent="$(cat "$ROOT/agents/intelliarch.md")"
echo "$agent" | grep -qi 'not a pstack fork' && ok "agent: not a fork" || bad "agent missing not-a-fork"
echo "$agent" | grep -q 'p10ns11y/skills' && ok "agent: skills remote" || bad "agent missing skills remote"

readme="$(cat "$ROOT/README.md")"
echo "$readme" | grep -q 'pstack-engineering.md' && ok "README points at engineering note" || bad "README missing engineering pointer"
if echo "$readme" | grep -q 'Key Concepts'; then bad "README pasted the engineering essay"; else ok "README did not paste the essay"; fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
