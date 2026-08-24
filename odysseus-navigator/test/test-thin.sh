#!/usr/bin/env bash
# Thin-plugin contract: faster intelli nail, not a second EVA.
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
need commands/odysseus.md
need commands/odysseus-core.md
need cursor/commands/odysseus.md
need cursor/commands/odysseus-core.md
need agents/odysseus-navigator.md
need skills/odysseus-navigator/SKILL.md

if [[ -d "$ROOT/c" ]]; then bad "c/ present — EVA owns the tether"; else ok "no c/"; fi
if [[ -d "$ROOT/rust" ]]; then bad "rust/ present — mission-map owns kernels"; else ok "no rust/"; fi
if find "$ROOT" -name '*.rhai' | grep -q .; then bad ".rhai present — EVA/arch-machine own workflows"; else ok "no rhai"; fi
if [[ -d "$ROOT/hooks" ]] || [[ -f "$ROOT/hooks.json" ]]; then bad "hooks present — would lecture every tool (Winds)"; else ok "no hooks"; fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "odysseus-navigator"' && ok "plugin.json name" || bad "plugin.json name"
echo "$pj" | grep -qi 'eva\|control-graph\|ithaca\|core' && ok "plugin.json mentions ecosystem" || bad "plugin.json description too vague"

core="$(cat "$ROOT/commands/odysseus-core.md")"
echo "$core" | grep -qi 'at most one' && ok "core: at most one mistake" || bad "core missing at most one"
echo "$core" | grep -qi 'no subagents' && ok "core: no subagents" || bad "core allows subagents"
echo "$core" | grep -qi 'eva_hook' && ok "core: eva_hook" || bad "core missing eva_hook"
echo "$core" | grep -qi 'cg_hook' && ok "core: cg_hook" || bad "core missing cg_hook"
if echo "$core" | grep -qi 'not start EVA'; then
  ok "core refuses EVA ritual"
elif echo "$core" | grep -q 'Prior→Probe→Simulate→Score'; then
  bad "core inlines EVA"
else
  ok "core does not inline EVA DAG"
fi

full="$(cat "$ROOT/commands/odysseus.md")"
echo "$full" | grep -qi 'do not inline' && ok "full: do not inline" || bad "full missing no-inline"

agent="$(cat "$ROOT/agents/odysseus-navigator.md")"
echo "$agent" | grep -qi 'not eva priors' && ok "agent: not EVA priors" || bad "agent looks like a prior fork"
echo "$agent" | grep -c '^---' | grep -q '[1-9]' && ok "agent frontmatter" || bad "agent frontmatter"

if [[ -e "$ROOT/skills/odysseus-navigator/SKILL.md" ]]; then
  if [[ -L "$ROOT/skills/odysseus-navigator" ]]; then
    ok "skills/odysseus-navigator is symlink (SoT in library)"
  elif [[ -f "$ROOT/skills/odysseus-navigator/SKILL.md" ]]; then
    ok "skills/odysseus-navigator bundled"
  else
    bad "skills/odysseus-navigator missing SKILL.md"
  fi
else
  bad "skills/odysseus-navigator/SKILL.md missing"
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
