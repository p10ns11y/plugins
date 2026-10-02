#!/usr/bin/env bash
# Concordance plugin: one card, no vendor client, no route decision.
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
need commands/concordance.md
need agents/concordance.md
need skills/concordance/SKILL.md
need skills/concordance/references/card.md

if find "$ROOT" \( -name '*.py' -o -name '*.ts' -o -name 'package.json' \) | grep -q .; then
  bad "vendor client present"
else
  ok "no vendor client"
fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "concordance"' && ok "name" || bad "name"
echo "$pj" | grep -q 'p_dm >= tau' && ok "plugin states the proceed rule" || bad "plugin missing proceed rule"

rule='proceed only when agree is yes and p_dm >= tau'
for surface in skills/concordance/SKILL.md commands/concordance.md agents/concordance.md README.md; do
  if grep -Fq "$rule" "$ROOT/$surface"; then
    ok "proceed rule in $surface"
  else
    bad "proceed rule missing in $surface"
  fi
done

skill="$(cat "$ROOT/skills/concordance/SKILL.md")"
for field in label_dm label_llm agree p_dm kappa_window proceed hold; do
  echo "$skill" | grep -q "$field" && ok "field $field" || bad "missing field $field"
done
echo "$skill" | grep -Fq 'intelli-route routes the hold' && ok "hold returns to the router" || bad "hold does not return to the router"
echo "$skill" | grep -Fq 'does not pick a load' && ok "skill does not pick a load" || bad "skill picks a load"
echo "$skill" | grep -Fq 'does not call a model vendor' && ok "no vendor call" || bad "vendor disclaimer missing"
if echo "$skill" | grep -Eq 'route `light`|route `card`|route `empty`'; then
  bad "skill computes a route"
else
  ok "skill does not compute a route"
fi

cmd="$(cat "$ROOT/commands/concordance.md")"
echo "$cmd" | grep -Fq 'intelli-route routes the hold' && ok "command returns the hold" || bad "command keeps the hold"
echo "$cmd" | grep -q 'kappa_window' && ok "command has kappa_window" || bad "command missing kappa_window"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q 'typesafe.ai/blog/introducing-system-one-models-and-jev' && ok "notices System One" || bad "missing System One credit"
echo "$notice" | grep -q 'does not call that API' && ok "no vendor call in NOTICE" || bad "NOTICE vendor disclaimer missing"
echo "$notice" | grep -q "Cohen's kappa" && ok "notices kappa" || bad "missing kappa credit"

card="$(cat "$ROOT/skills/concordance/references/card.md")"
echo "$card" | grep -Fq 'label_dm=<token>' && ok "log line" || bad "missing log line"
echo "$card" | grep -Fq 'Leave `kappa_window` empty' && ok "kappa stays empty" || bad "kappa may be invented"
echo "$card" | grep -Fq 'Kappa does not change `act`' && ok "kappa does not change act" || bad "kappa changes act"

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
