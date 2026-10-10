#!/usr/bin/env bash
# SI plugin: one spine, four profiles, no vendor client.
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
need commands/si.md
need agents/si.md
need skills/peram_senior_mlai_engineer/SKILL.md
need skills/peram_senior_mlai_engineer/references/workflow-card.md
need skills/peram_data_workflows/SKILL.md
need skills/peram_si_native_workflows/SKILL.md
need skills/peram_si_service_harness/SKILL.md
need skills/peram_deterministic_saas/SKILL.md
need skills/peram_infra/SKILL.md
need skills/peram_devex/SKILL.md

if find "$ROOT" \( -name '*.py' -o -name '*.ts' -o -name 'package.json' \) | grep -q .; then
  bad "vendor client present"
else
  ok "no vendor client"
fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "si"' && ok "name" || bad "name"

rule='Load the spine, then **one** profile.'
grep -Fq "$rule" "$ROOT/README.md" && ok "one profile" || bad "README missing one-profile rule"
grep -Fq 'SI is the system workflow that owns the write' "$ROOT/commands/si.md" && ok "command defines SI" || bad "command missing SI"
grep -Fq 'Do not' "$ROOT/agents/si.md" && ok "agent refuses the family" || bad "agent missing refusal"
grep -Fq 'peram_si_native_workflows' "$ROOT/skills/peram_senior_mlai_engineer/SKILL.md" && ok "spine routes SI-native" || bad "spine missing SI-native"
grep -Fq 'peram_si_service_harness' "$ROOT/skills/peram_senior_mlai_engineer/SKILL.md" && ok "spine routes SI service" || bad "spine missing SI service"
grep -Fq 'Security is what scales' "$ROOT/skills/peram_infra/SKILL.md" && ok "infra scales security" || bad "infra missing security rule"
grep -Fq 'The fast path does not turn security off' "$ROOT/skills/peram_devex/SKILL.md" && ok "devex keeps security" || bad "devex missing security rule"

if grep -R -n -E 'peram_ai_|AI-native|AI as a service' "$ROOT/skills" "$ROOT/commands" "$ROOT/agents" "$ROOT/README.md"; then
  bad "AI name still present"
else
  ok "profiles use SI"
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
