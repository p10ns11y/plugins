#!/usr/bin/env bash
# Placement plugin: one closed set, no vendor client.
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
need commands/split-machine.md
need agents/split-machine.md
need skills/split-machine/SKILL.md
need skills/split-machine/references/placement.md

if find "$ROOT" -name '*.py' -o -name '*.ts' -o -name 'package.json' | grep -q .; then
  bad "vendor client present"
else
  ok "no vendor client"
fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "split-machine"' && ok "name" || bad "name"
echo "$pj" | grep -q 'System One' && ok "plugin names System One" || bad "plugin missing System One"

skill="$(cat "$ROOT/skills/split-machine/SKILL.md")"
for id in earth-qpu orbit-link gpu-factory bqp-slice system-one system-two; do
  echo "$skill" | grep -q "$id" && ok "substrate $id" || bad "missing substrate $id"
done
echo "$skill" | grep -q 'do not evolve the Hamiltonian' && ok "wording law" || bad "missing wording law"
echo "$skill" | grep -q 'Low confidence does not branch' && ok "low confidence stops" || bad "confidence gate missing"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q '2103445290602688619' && ok "notices the wording post" || bad "missing wording post"
echo "$notice" | grep -q '2103435845294313521' && ok "notices the orbit post" || bad "missing orbit post"
echo "$notice" | grep -q '2103432723310223623' && ok "notices the NISQ post" || bad "missing NISQ post"
echo "$notice" | grep -q 'typesafe.ai/blog/introducing-system-one-models-and-jev' && ok "notices System One" || bad "missing System One credit"
echo "$notice" | grep -q 'does not call that API' && ok "no vendor call" || bad "vendor disclaimer missing"

place="$(cat "$ROOT/skills/split-machine/references/placement.md")"
echo "$place" | grep -q 'NISQ' && ok "placement refuses NISQ inference" || bad "placement missing NISQ"
echo "$place" | grep -q 'dense' && ok "placement refuses dense matmul" || bad "placement missing dense matmul"

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
