#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

script="$ROOT/scripts/mm-lifeos-graph"
grep -q 'This tick alignment' "$script"
if grep -q 'cosθ' "$script" || grep -q 'û_G' "$script"; then
  echo "vault writer still prints an angle"
  exit 1
fi
if grep -q '\\partial T' "$ROOT/README.md" "$ROOT/skills/mission-map/SKILL.md"; then
  echo "effort step still ranks a partial this tree does not compute"
  exit 1
fi

mkdir -p "$TMP/maps" "$TMP/life/UI"
cp "$ROOT/examples/sample-map.json" "$TMP/maps/cash-path-now.json"

# First night: no last-run → no delta.
kind=$(
  MISSION_MAP_NOTIFY=0 \
  MISSION_MAPS="$TMP/maps" \
  LIFEOS="$TMP/life" \
  MISSION_MAP_GRAPH="$ROOT/rust/target/debug/mission-map-graph" \
  "$ROOT/scripts/mm-lifeos-graph"
)
test "$kind" = "on-path"
grep -q 'heading' "$TMP/life/UI/Mission.md"
grep -q 'flowchart TB' "$TMP/life/UI/Mission.md"
grep -q '| What | Status |' "$TMP/life/UI/Mission.md"
grep -q 'Do this' "$TMP/life/UI/Mission.md"
test -f "$TMP/maps/cash-path-last-run.json"

# Mark pack Done and re-run → progress, remaining T drops.
python3 - <<'PY' "$TMP/maps/cash-path-now.json"
import json, sys
p = sys.argv[1]
with open(p) as f:
    m = json.load(f)
for s in m["stages"]:
    if s["id"] == "pack":
        s["class"] = "Done"
with open(p, "w") as f:
    json.dump(m, f)
PY

kind=$(
  MISSION_MAP_NOTIFY=0 \
  MISSION_MAPS="$TMP/maps" \
  LIFEOS="$TMP/life" \
  MISSION_MAP_GRAPH="$ROOT/rust/target/debug/mission-map-graph" \
  "$ROOT/scripts/mm-lifeos-graph"
)
# next_do may be empty (Wait) after pack is Done
grep -q 'Change since last snapshot' "$TMP/life/UI/Mission.md"
test -f "$TMP/life/UI/_private.Mission.md"

echo "test-lifeos-graph ok"
