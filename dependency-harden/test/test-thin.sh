#!/usr/bin/env bash
# dependency-harden: port copy, supply-chain-harden stays out, skills-repo URLs stay canonical.
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
need commands/dependency-harden.md
need commands/devcontainer.md
need skills/fix-dependency-security/SKILL.md
need skills/upgrade-packages/SKILL.md
need skills/audit-allow-builds/SKILL.md
need skills/audit-ide-dependencies/SKILL.md
need skills/devcontainer-hardened/SKILL.md
need .grok/workflows/dependency-harden.md
need .grok/workflows/dependency-harden.rhai

mark='Port copy. Canonical file remains in https://github.com/p10ns11y/skills on master.'
for skill in fix-dependency-security upgrade-packages audit-allow-builds audit-ide-dependencies devcontainer-hardened; do
  if grep -Fq "$mark" "$ROOT/skills/$skill/SKILL.md"; then
    ok "port mark in $skill"
  else
    bad "port mark missing in $skill"
  fi
done

chain="$(cat "$ROOT/commands/dependency-harden.md")"
echo "$chain" | grep -Fq 'Load skill **fix-dependency-security**' && ok "command loads fix-dependency-security" || bad "command misses fix-dependency-security"
echo "$chain" | grep -Fq '**upgrade-packages**' && ok "command loads upgrade-packages" || bad "command misses upgrade-packages"
echo "$chain" | grep -Fq '**audit-allow-builds**' && ok "command loads audit-allow-builds" || bad "command misses audit-allow-builds"
echo "$chain" | grep -Fq '**audit-ide-dependencies**' && ok "command loads audit-ide-dependencies" || bad "command misses audit-ide-dependencies"
echo "$chain" | grep -Fq 'Do not load supply-chain-harden' && ok "command skips supply-chain-harden" || bad "command loads supply-chain-harden"

container="$(cat "$ROOT/commands/devcontainer.md")"
echo "$container" | grep -Fq 'Load skill **devcontainer-hardened**' && ok "devcontainer loads skill" || bad "devcontainer misses skill"

if [[ -d "$ROOT/skills/supply-chain-harden" ]]; then
  bad "supply-chain-harden was copied"
else
  ok "supply-chain-harden absent"
fi

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -Fq 'intelli-route' && ok "notice keeps intelli-route on the skills repo" || bad "notice misses intelli-route"
echo "$notice" | grep -Fq 'fix-dependency-security/SKILL.md' && ok "notice names canonical fix" || bad "notice misses canonical fix"

workflow="$(cat "$ROOT/.grok/workflows/dependency-harden.md" "$ROOT/.grok/workflows/dependency-harden.rhai")"
if echo "$workflow" | grep -Fq 'supply-chain-harden'; then
  bad "workflow still names supply-chain-harden"
else
  ok "workflow renamed the duplicate chain step"
fi
echo "$workflow" | grep -Fq 'fix-dependency-security' && ok "workflow names fix-dependency-security" || bad "workflow misses fix-dependency-security"

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
