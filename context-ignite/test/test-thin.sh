#!/usr/bin/env bash
# context-ignite: port copy, prune then synthesis, skills-repo URLs stay canonical.
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
need commands/context-ignite.md
need skills/ai-optimization/SKILL.md
need skills/ai-optimization/Makefile
need skills/ai-optimization/c/context_sage.c
need skills/ai-optimization/c/Makefile
need skills/ai-optimization/rust/Cargo.toml
need skills/ai-optimization/rust/src/main.rs
need skills/architecture-synthesis/SKILL.md
need .grok/workflows/context-ignite.rhai
need .grok/workflows/context-ignite.md

if [[ -e "$ROOT/skills/fusion-sage" ]]; then
  bad "fusion-sage was copied"
else
  ok "fusion-sage absent"
fi

if [[ -e "$ROOT/skills/ai-optimization/scripts/context-sage.py" ]]; then
  bad "python packer still present"
else
  ok "python packer absent"
fi

mark='Port copy. Canonical file remains in https://github.com/p10ns11y/skills on master.'
for skill in ai-optimization architecture-synthesis; do
  if grep -Fq "$mark" "$ROOT/skills/$skill/SKILL.md"; then
    ok "port mark in $skill"
  else
    bad "port mark missing in $skill"
  fi
done

cmd="$(cat "$ROOT/commands/context-ignite.md")"
echo "$cmd" | grep -Fq 'Load skill **ai-optimization**, then load skill **architecture-synthesis**.' && ok "command loads prune then synthesis" || bad "command order is wrong"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -Fq 'intelli-route' && ok "notice keeps intelli-route on the skills repo" || bad "notice misses intelli-route"
echo "$notice" | grep -Fq 'ai-optimization/SKILL.md' && ok "notice names canonical prune" || bad "notice misses canonical prune"
echo "$notice" | grep -Fq 'architecture-synthesis/SKILL.md' && ok "notice names canonical synthesis" || bad "notice misses canonical synthesis"
echo "$notice" | grep -Fq 'fusion-sage' && ok "notice records fusion-sage discovery off" || bad "notice misses fusion-sage"

readme="$(cat "$ROOT/README.md")"
echo "$readme" | grep -Fq 'If a host compaction pass beats bin/context-sage on a real repo, delete the prune half and keep architecture-synthesis.' && ok "readme keeps the compaction exit" || bad "readme misses the compaction exit"
echo "$readme" | grep -Fq 'make -C skills/ai-optimization' && ok "readme names the rust packer build" || bad "readme misses the rust packer build"
echo "$readme" | grep -Fq 'c/context_sage.c' && ok "readme names the c scanner" || bad "readme misses the c scanner"
echo "$readme" | grep -Fq '**Spec.**' && ok "readme names the spec" || bad "readme misses the spec"
echo "$readme" | grep -Fq '**Policy.**' && ok "readme names the policy" || bad "readme misses the policy"
echo "$readme" | grep -Fq '**Before/after.**' && ok "readme names the before/after" || bad "readme misses the before/after"

workflow="$(cat "$ROOT/.grok/workflows/context-ignite.rhai" "$ROOT/.grok/workflows/context-ignite.md")"
echo "$workflow" | grep -Fq 'architecture-synthesis' && ok "workflow points at architecture-synthesis" || bad "workflow misses architecture-synthesis"
if echo "$workflow" | grep -Fq 'fusion-sage'; then
  bad "workflow still names fusion-sage"
else
  ok "workflow does not name fusion-sage"
fi

if [[ -d "$ROOT/../dependency-harden" ]]; then
  bad "dependency-harden was created in this port"
else
  ok "dependency-harden absent"
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
