#!/usr/bin/env bash
# Trust layers. No merge bot, no vendored pstack.
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
need commands/trust-stack.md
need agents/trust-stack.md
need skills/trust-stack/SKILL.md
need skills/trust-stack/references/layers.md
need bend/gate.bend
need bend/LAWS.bend
need bend/PROOF.bend
need test/bend-critical.sh

if [[ -d "$ROOT/poteto-mode" || -d "$ROOT/playbooks" ]]; then
  bad "pstack vendored"
else
  ok "no pstack copy"
fi

skill="$(cat "$ROOT/skills/trust-stack/SKILL.md")"
for id in shape check watch skill guide; do
  echo "$skill" | grep -q "\`$id\`" && ok "layer $id" || bad "missing layer $id"
done
echo "$skill" | grep -q 'This plugin does not merge' && ok "does not merge" || bad "merge guard missing"
echo "$skill" | grep -q 'codebase is the memory' && ok "memory axiom" || bad "memory axiom missing"
echo "$skill" | grep -q 'One owner' && ok "one owner" || bad "owner rule missing"

if echo "$skill" | grep -qi 'agents merge'; then
  bad "skill tells agents to merge"
else
  ok "skill does not instruct a merge"
fi

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q '2102050467505430555' && ok "notices the talk" || bad "missing talk"
echo "$notice" | grep -q 'bend-lang.com' && ok "notices Bend" || bad "missing Bend"
echo "$notice" | grep -q 'does not merge' && ok "notice refuses merge" || bad "notice missing merge refusal"
echo "$notice" | grep -q 'Lauren Tan' && ok "credits Lauren Tan" || bad "missing credit"
echo "$skill" | grep -q 'bend PROOF.bend' && ok "shape layer names the bend gate" || bad "missing bend gate"
echo "$skill" | grep -q 'that check was not run' && ok "absent bend is not a pass" || bad "absent bend treated as a pass"

if bash "$ROOT/test/bend-critical.sh" | tee /dev/stderr | grep -q -e 'All terms check.' -e 'bend not installed'; then
  ok "bend critical gate"
else
  bad "bend critical gate"
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
