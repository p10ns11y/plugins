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
grep -F -q '| **Arrive when** | started a decent full-time role |' "$TMP/life/UI/Mission.md"
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

python3 - <<'PY' "$TMP"
import json, os, sys
temporary_root = sys.argv[1]

def write_map(fixture_name, map_document):
    maps_directory = os.path.join(temporary_root, fixture_name, "maps")
    os.makedirs(maps_directory, exist_ok=True)
    os.makedirs(os.path.join(temporary_root, fixture_name, "life", "UI"), exist_ok=True)
    now_path = os.path.join(maps_directory, "now.json")
    with open(now_path, "w") as map_file:
        json.dump(map_document, map_file)

def wait_stage(stage_id, duration_weeks, stage_label):
    return {
        "id": stage_id,
        "a": duration_weeks,
        "m": duration_weeks,
        "b": duration_weeks,
        "depends_on": [],
        "class": "Wait",
        "what": stage_label,
    }

write_map("named-do-without-do-stage", {
    "g": "a finished sample",
    "tick": {"named_do": "send the weekly note"},
    "stages": [wait_stage("hold", 1, "hold for a reply")],
})
write_map("waiting-without-named-do", {
    "g": "a finished sample",
    "stages": [wait_stage("hold", 1, "hold for a reply")],
})
write_map("goal-date-already-passed", {
    "g": "a closed sample",
    "g_by": "2020-01-15",
    "stages": [wait_stage("hold", 1, "hold for a reply")],
})
write_map("remaining-chain-past-stated-month", {
    "g": "early October 2026",
    "stages": [wait_stage("draft", 2, "draft the note")],
})
write_map("goal-date-still-ahead", {
    "g": "a later sample",
    "g_by": "2035-01-15",
    "stages": [wait_stage("review", 1, "review the note")],
})
PY

run_lifeos() {
  maps_directory=$1
  life_directory=$2
  today_override=$3
  if [ -n "$today_override" ]; then
    MISSION_MAP_TODAY="$today_override" \
      MISSION_MAP_NOTIFY=0 \
      MISSION_MAP_NOW="$maps_directory/now.json" \
      MISSION_MAPS="$maps_directory" \
      LIFEOS="$life_directory" \
      MISSION_MAP_GRAPH="$ROOT/rust/target/debug/mission-map-graph" \
      "$script" >/dev/null
  else
    env -u MISSION_MAP_TODAY \
      MISSION_MAP_NOTIFY=0 \
      MISSION_MAP_NOW="$maps_directory/now.json" \
      MISSION_MAPS="$maps_directory" \
      LIFEOS="$life_directory" \
      MISSION_MAP_GRAPH="$ROOT/rust/target/debug/mission-map-graph" \
      "$script" >/dev/null
  fi
}

expect_line() {
  mission_page=$1
  expected_text=$2
  if ! grep -F -q "$expected_text" "$mission_page"; then
    echo "missing: $expected_text" >&2
    exit 1
  fi
}

forbid_line() {
  mission_page=$1
  unexpected_text=$2
  if grep -F -q "$unexpected_text" "$mission_page"; then
    echo "unexpected: $unexpected_text" >&2
    exit 1
  fi
}

notify_stub_directory="$TMP/bin"
mkdir -p "$notify_stub_directory"
cat > "$notify_stub_directory/notify-send" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "${NOTIFY_LOG:?}"
EOF
chmod +x "$notify_stub_directory/notify-send"
named_do_fixture="$TMP/named-do-without-do-stage"
NOTIFY_LOG="$TMP/named-do-without-do-stage-notify.log"
: > "$NOTIFY_LOG"
NOTIFY_LOG="$NOTIFY_LOG" \
  PATH="$notify_stub_directory:$PATH" \
  WAYLAND_DISPLAY=wayland-0 \
  MISSION_MAP_NOTIFY=1 \
  MISSION_MAP_NOW="$named_do_fixture/maps/now.json" \
  MISSION_MAPS="$named_do_fixture/maps" \
  LIFEOS="$named_do_fixture/life" \
  MISSION_MAP_GRAPH="$ROOT/rust/target/debug/mission-map-graph" \
  env -u MISSION_MAP_TODAY \
  "$script" >/dev/null
if [ -s "$NOTIFY_LOG" ]; then
  echo "notified with no Do" >&2
  exit 1
fi

mission_page="$named_do_fixture/life/UI/Mission.md"
expect_line "$mission_page" '**Do this now:** send the weekly note'
expect_line "$mission_page" '| **Do this now** | send the weekly note |'
expect_line "$mission_page" '| **Arrive when** | a finished sample |'
forbid_line "$mission_page" 'Do this now:** Do this now'
forbid_line "$mission_page" '| **Do this now** | Do this now |'

waiting_fixture="$TMP/waiting-without-named-do"
run_lifeos "$waiting_fixture/maps" "$waiting_fixture/life" ""
mission_page="$waiting_fixture/life/UI/Mission.md"
expect_line "$mission_page" '**Do this now:** Nothing to do now; waiting on them.'
expect_line "$mission_page" '| **Do this now** | Nothing to do now; waiting on them. |'
forbid_line "$mission_page" 'Do this now:** Do this now'
forbid_line "$mission_page" '| **Do this now** | Do this now |'

passed_goal_fixture="$TMP/goal-date-already-passed"
run_lifeos "$passed_goal_fixture/maps" "$passed_goal_fixture/life" "2026-10-04"
mission_page="$passed_goal_fixture/life/UI/Mission.md"
expect_line "$mission_page" '| **Arrive when** | a closed sample (stale: the target date has passed; restate the goal) |'

chain_past_month_fixture="$TMP/remaining-chain-past-stated-month"
run_lifeos "$chain_past_month_fixture/maps" "$chain_past_month_fixture/life" "2026-10-04"
mission_page="$chain_past_month_fixture/life/UI/Mission.md"
expect_line "$mission_page" '| **Arrive when** | early October 2026 (stale: the remaining chain runs past the target date; restate the goal) |'
forbid_line "$mission_page" 'the target date has passed'

future_goal_fixture="$TMP/goal-date-still-ahead"
run_lifeos "$future_goal_fixture/maps" "$future_goal_fixture/life" "2026-10-04"
mission_page="$future_goal_fixture/life/UI/Mission.md"
expect_line "$mission_page" '| **Arrive when** | a later sample |'
forbid_line "$mission_page" '(stale:'

echo "test-lifeos-graph ok"
