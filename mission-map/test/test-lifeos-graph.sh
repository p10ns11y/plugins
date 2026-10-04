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
root = sys.argv[1]

def write(name, doc):
    maps = os.path.join(root, name, "maps")
    os.makedirs(maps, exist_ok=True)
    os.makedirs(os.path.join(root, name, "life", "UI"), exist_ok=True)
    with open(os.path.join(maps, "now.json"), "w") as f:
        json.dump(doc, f)

def stage(sid, weeks, what):
    return {
        "id": sid,
        "a": weeks,
        "m": weeks,
        "b": weeks,
        "depends_on": [],
        "class": "Wait",
        "what": what,
    }

write("a", {
    "g": "a finished sample",
    "tick": {"named_do": "send the weekly note"},
    "stages": [stage("hold", 1, "hold for a reply")],
})
write("b", {
    "g": "a finished sample",
    "stages": [stage("hold", 1, "hold for a reply")],
})
write("c", {
    "g": "a closed sample",
    "g_by": "2020-01-15",
    "stages": [stage("hold", 1, "hold for a reply")],
})
write("d", {
    "g": "early October 2026",
    "stages": [stage("draft", 2, "draft the note")],
})
write("e", {
    "g": "a later sample",
    "g_by": "2035-01-15",
    "stages": [stage("review", 1, "review the note")],
})
PY

run_lifeos() {
  maps=$1
  life=$2
  today=$3
  if [ -n "$today" ]; then
    MISSION_MAP_TODAY="$today" \
      MISSION_MAP_NOTIFY=0 \
      MISSION_MAP_NOW="$maps/now.json" \
      MISSION_MAPS="$maps" \
      LIFEOS="$life" \
      MISSION_MAP_GRAPH="$ROOT/rust/target/debug/mission-map-graph" \
      "$script" >/dev/null
  else
    env -u MISSION_MAP_TODAY \
      MISSION_MAP_NOTIFY=0 \
      MISSION_MAP_NOW="$maps/now.json" \
      MISSION_MAPS="$maps" \
      LIFEOS="$life" \
      MISSION_MAP_GRAPH="$ROOT/rust/target/debug/mission-map-graph" \
      "$script" >/dev/null
  fi
}

expect_line() {
  if ! grep -F -q "$2" "$1"; then
    echo "missing: $2" >&2
    exit 1
  fi
}

forbid_line() {
  if grep -F -q "$2" "$1"; then
    echo "unexpected: $2" >&2
    exit 1
  fi
}

note_bin="$TMP/bin"
mkdir -p "$note_bin"
cat > "$note_bin/notify-send" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "${NOTIFY_LOG:?}"
EOF
chmod +x "$note_bin/notify-send"
NOTIFY_LOG="$TMP/a-notify.log"
: > "$NOTIFY_LOG"
NOTIFY_LOG="$NOTIFY_LOG" \
  PATH="$note_bin:$PATH" \
  WAYLAND_DISPLAY=wayland-0 \
  MISSION_MAP_NOTIFY=1 \
  MISSION_MAP_NOW="$TMP/a/maps/now.json" \
  MISSION_MAPS="$TMP/a/maps" \
  LIFEOS="$TMP/a/life" \
  MISSION_MAP_GRAPH="$ROOT/rust/target/debug/mission-map-graph" \
  env -u MISSION_MAP_TODAY \
  "$script" >/dev/null
if [ -s "$NOTIFY_LOG" ]; then
  echo "notified with no Do" >&2
  exit 1
fi

md="$TMP/a/life/UI/Mission.md"
expect_line "$md" '**Do this now:** send the weekly note'
expect_line "$md" '| **Do this now** | send the weekly note |'
expect_line "$md" '| **Arrive when** | a finished sample |'
forbid_line "$md" 'Do this now:** Do this now'
forbid_line "$md" '| **Do this now** | Do this now |'

run_lifeos "$TMP/b/maps" "$TMP/b/life" ""
md="$TMP/b/life/UI/Mission.md"
expect_line "$md" '**Do this now:** Nothing to do now; waiting on them.'
expect_line "$md" '| **Do this now** | Nothing to do now; waiting on them. |'
forbid_line "$md" 'Do this now:** Do this now'
forbid_line "$md" '| **Do this now** | Do this now |'

run_lifeos "$TMP/c/maps" "$TMP/c/life" "2026-10-04"
md="$TMP/c/life/UI/Mission.md"
expect_line "$md" '| **Arrive when** | a closed sample (stale: the target date has passed; restate the goal) |'

run_lifeos "$TMP/d/maps" "$TMP/d/life" "2026-10-04"
md="$TMP/d/life/UI/Mission.md"
expect_line "$md" '| **Arrive when** | early October 2026 (stale: the remaining chain runs past the target date; restate the goal) |'
forbid_line "$md" 'the target date has passed'

run_lifeos "$TMP/e/maps" "$TMP/e/life" "2026-10-04"
md="$TMP/e/life/UI/Mission.md"
expect_line "$md" '| **Arrive when** | a later sample |'
forbid_line "$md" '(stale:'

echo "test-lifeos-graph ok"
