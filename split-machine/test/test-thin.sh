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
for id in earth-qpu orbit-link beam-switch orbit-screen gpu-factory bqp-slice system-one system-two; do
  echo "$skill" | grep -q "$id" && ok "substrate $id" || bad "missing substrate $id"
done
echo "$skill" | grep -q 'do not evolve the Hamiltonian' && ok "wording law" || bad "missing wording law"
echo "$skill" | grep -q 'Low confidence does not branch' && ok "low confidence stops" || bad "low confidence does not stop"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q '2103445290602688619' && ok "notices the wording post" || bad "missing wording post"
echo "$notice" | grep -q '2103435845294313521' && ok "notices the orbit post" || bad "missing orbit post"
echo "$notice" | grep -q '2103432723310223623' && ok "notices the NISQ post" || bad "missing NISQ post"
echo "$notice" | grep -q 'typesafe.ai/blog/introducing-system-one-models-and-jev' && ok "notices System One" || bad "missing System One credit"
echo "$notice" | grep -q 'does not call that API' && ok "no vendor call" || bad "vendor disclaimer missing"
echo "$notice" | grep -q 'starlink.com/updates/stargaze' && ok "notices Stargaze" || bad "missing Stargaze credit"
echo "$notice" | grep -q 'starlink.com/updates/starlink-beam-switching' && ok "notices beam switching" || bad "missing beam-switching credit"

place="$(cat "$ROOT/skills/split-machine/references/placement.md")"
cmd="$(cat "$ROOT/commands/split-machine.md")"
agent="$(cat "$ROOT/agents/split-machine.md")"
echo "$place" | grep -q 'NISQ' && ok "placement refuses NISQ inference" || bad "placement missing NISQ"
echo "$place" | grep -q 'dense' && ok "placement refuses dense matmul" || bad "placement missing dense matmul"
echo "$place" | grep -q 'not an entanglement link' && ok "Stargaze stays classical" || bad "Stargaze fused with entanglement"
echo "$place" | grep -q 'Call a LEO radio handover an entangled pair' && ok "beam-switch stays classical" || bad "beam-switch fused with entanglement"
echo "$place" | grep -q 'free-fall clock or interferometer' && ok "free-fall instrument refused" || bad "missing free-fall refusal"
echo "$cmd" | grep -q 'free-fall clock or interferometer' && ok "command refuses free-fall link" || bad "command missing free-fall refusal"
echo "$cmd" | grep -q 'star tracker called a telescope' && ok "command refuses star tracker" || bad "command missing star-tracker refusal"
echo "$agent" | grep -q 'stop and ask' && ok "agent asks on a free-fall instrument" || bad "agent invents a substrate"
for id in earth-qpu orbit-link beam-switch orbit-screen gpu-factory bqp-slice system-one system-two; do
  echo "$place" | grep -q "| \`$id\` |" && ok "placement row $id" || bad "placement missing row $id"
  echo "$cmd" | grep -q "$id" && ok "command names $id" || bad "command missing $id"
done
orbit_row="$(printf '%s\n' "$place" | grep '| `orbit-link` |')"
if printf '%s\n' "$orbit_row" | grep -q 'line-of-sight'; then bad "orbit-link still claims line-of-sight"; else ok "orbit-link drops line-of-sight"; fi
if printf '%s\n' "$orbit_row" | grep -q 'free-fall'; then bad "orbit-link still claims free-fall"; else ok "orbit-link drops free-fall"; fi
if printf '%s\n' "$place" | grep -q '2,000 km'; then bad "unsupported LEO altitude bound"; else ok "no invented LEO altitude bound"; fi
if printf '%s\n' "$place" | grep -q '70 m/s'; then bad "unsupported closing rate"; else ok "no invented closing rate"; fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
