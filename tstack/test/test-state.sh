#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$ROOT/scripts/tstack-state"
export PATH=/usr/bin:/bin
unset TSTACK_STATE_DB PULSE_MEMORY_DB
fail=0
OUT=""
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

must() {
  local label="$1"
  shift
  if OUT=$("$@"); then
    ok "$label"
  else
    local rc=$?
    printf '%s\n' "$OUT" >&2
    bad "$label exit $rc"
  fi
}

expect3() {
  local label="$1"
  shift
  if "$@" >/dev/null; then
    bad "$label expected 3 got 0"
  else
    local rc=$?
    [[ "$rc" -eq 3 ]] && ok "$label" || bad "$label exit $rc"
  fi
}

sql() {
  python3 - "$TSTACK_STATE_DB" "$1" <<'PY'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
row = con.execute(sys.argv[2]).fetchone()
if row is None:
    sys.exit(1)
print(row[0])
PY
}

fresh() {
  local dir
  dir="$(mktemp -d)"
  TSTACK_STATE_DB="$dir/state.sqlite"
  export TSTACK_STATE_DB
}

shape() {
  "$STATE" init >/dev/null
  "$STATE" map put --id loop --g Arrive >/dev/null
  "$STATE" stage put --map loop --id one --class Do --a 1 --m 2 --b 3 --label First --next 1 >/dev/null
  "$STATE" stage put --map loop --id two --class Do --a 1 --m 2 --b 4 --label Second --depends one >/dev/null
  "$STATE" stage put --map loop --id parked --class Park --a 1 --m 1 --b 1 --label Later >/dev/null
}

# Octal mode; GNU stat on Linux, BSD stat on macOS.
mode() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

admit() {
  "$STATE" pulse admit --key "$1" --snippet "$2" --source loop --time "$3" \
    --status user-stated --kind memory --lock "$4"
}

# Row 1, own db.
fresh
parent="$(dirname "$TSTACK_STATE_DB")"
parent_mode="$(mode "$parent")"
must "row 1 init" "$STATE" init
[[ "$(mode "$TSTACK_STATE_DB")" == "600" ]] && ok "row 1 mode 600" || bad "row 1 mode"
[[ "$(mode "$parent")" == "$parent_mode" ]] && ok "row 1 parent mode" || bad "row 1 parent mode"
python3 -c 'import json,sys; assert json.loads(sys.argv[1])["versions"]==[1,2,3]' "$OUT" \
  && ok "row 1 versions" || bad "row 1 versions"
must "row 1 init again" "$STATE" init
[[ "$(sql "SELECT COUNT(*) FROM schema_migrations")" == "3" ]] && ok "row 1 three rows" || bad "row 1 three rows"
[[ "$(sql "SELECT GROUP_CONCAT(version) FROM (SELECT version FROM schema_migrations ORDER BY version)")" == "1,2,3" ]] \
  && ok "row 1 versions stay" || bad "row 1 versions stay"
for extra in "$TSTACK_STATE_DB-wal" "$TSTACK_STATE_DB-shm"; do
  if [[ -f "$extra" ]]; then
    [[ "$(mode "$extra")" == "600" ]] && ok "row 1 $(basename "$extra")" || bad "row 1 $(basename "$extra")"
  fi
done

# Rows 2–8 share one db.
fresh
shape
ok "row 2 shape"
must "row 3 next" "$STATE" next --map loop
python3 -c 'import json,sys; assert json.loads(sys.argv[1])["stage_id"]=="one"' "$OUT" \
  && ok "row 3 stage one" || bad "row 3 stage"
expect3 "row 4 park" "$STATE" block open --map loop --stage parked --energy low
must "row 5 open" "$STATE" block open --map loop --stage one --energy high --plan "draft the note"
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert isinstance(d["id"], int) and d["map_id"]=="loop" and d["stage_id"]=="one"' "$OUT" \
  && ok "row 5 id" || bad "row 5 id"
expect3 "row 5 second open" "$STATE" block open --map loop --stage one --energy mid --plan "again"
[[ "$(sql "SELECT COUNT(*) FROM blocks WHERE status='open'")" == "1" ]] && ok "row 5 one open" || bad "row 5 one open"
expect3 "row 6 empty evidence" "$STATE" harvest add --map loop --stage one --result kept --evidence ""
[[ "$(sql "SELECT COUNT(*) FROM harvest_rows")" == "0" ]] && ok "row 6 no row" || bad "row 6 no row"
must "row 7 harvest" "$STATE" harvest add --map loop --stage one --result shipped --evidence "merged sha"
[[ "$(sql "SELECT COUNT(*) FROM harvest_rows")" == "1" ]] && ok "row 7 one row" || bad "row 7 one row"
[[ "$(sql "SELECT class FROM stages WHERE map_id='loop' AND stage_id='one'")" == "Do" ]] \
  && ok "row 7 class Do" || bad "row 7 class"
must "row 8 done" "$STATE" stage put --map loop --id one --class Done --a 1 --m 2 --b 3 --label First
must "row 8 report" "$STATE" apply-report --map loop --critical two --next two
must "row 8 next" "$STATE" next --map loop
python3 -c 'import json,sys; assert json.loads(sys.argv[1])["stage_id"]=="two"' "$OUT" \
  && ok "row 8 stage two" || bad "row 8 stage"
[[ "$(sql "SELECT class FROM stages WHERE map_id='loop' AND stage_id='one'")" == "Done" ]] \
  && ok "row 8 class Done" || bad "row 8 class"

# Row 9, fresh db.
fresh
"$STATE" init >/dev/null
must "row 9 admit" admit trace hello 2026-10-16T00:00:00Z open
must "row 9 list" "$STATE" pulse list
python3 -c 'import json,sys; rows=json.loads(sys.argv[1])["rows"]; assert any(r["nat_key"]=="trace" and r["snippet"]=="hello" for r in rows)' "$OUT" \
  && ok "row 9 listed" || bad "row 9 listed"
must "row 9 admit again" admit trace hello 2026-10-16T01:00:00Z open
[[ "$(sql "SELECT seen_count FROM memory_traces WHERE nat_key='trace'")" == "2" ]] \
  && ok "row 9 seen 2" || bad "row 9 seen"
[[ "$(sql "SELECT snippet FROM memory_traces WHERE nat_key='trace'")" == "hello" ]] \
  && ok "row 9 snippet" || bad "row 9 snippet"

# Row 10, fresh db.
fresh
"$STATE" init >/dev/null
must "row 10 lock" admit trace alpha 2026-10-16T00:00:00Z locked
must "row 10 disagree" admit trace beta 2026-10-16T01:00:00Z locked
[[ "$(sql "SELECT snippet FROM memory_traces WHERE nat_key='trace'")" == "alpha" ]] \
  && ok "row 10 old snippet" || bad "row 10 old snippet"
[[ "$(sql "SELECT snippet FROM memory_traces WHERE nat_key='trace-2'")" == "beta" ]] \
  && ok "row 10 trace-2" || bad "row 10 trace-2"
[[ "$(sql "SELECT COUNT(*) FROM conflicts")" == "1" ]] && ok "row 10 one conflict" || bad "row 10 one conflict"
[[ "$(sql "SELECT resolution FROM conflicts")" == "not in the evidence" ]] \
  && ok "row 10 resolution" || bad "row 10 resolution"
[[ "$(sql "SELECT subject FROM conflicts")" == "trace" ]] && ok "row 10 subject" || bad "row 10 subject"
[[ "$(sql "SELECT ts FROM conflicts")" == "2026-10-16T01:00:00Z" ]] && ok "row 10 ts" || bad "row 10 ts"
must "row 10 same snippet" admit trace alpha 2026-10-16T02:00:00Z locked
[[ "$(sql "SELECT seen_count FROM memory_traces WHERE nat_key='trace'")" == "2" ]] \
  && ok "row 10 seen bump" || bad "row 10 seen bump"
[[ "$(sql "SELECT COUNT(*) FROM conflicts")" == "1" ]] && ok "row 10 no new conflict" || bad "row 10 no new conflict"

# Row 11, fresh db.
fresh
"$STATE" init >/dev/null
must "row 11 archive" "$STATE" pulse archive --source loop --payload archive-token-row11
[[ "$(sql "SELECT COUNT(*) FROM archive_events")" == "1" ]] && ok "row 11 archive row" || bad "row 11 archive row"
must "row 11 list" "$STATE" pulse list
python3 -c 'import sys; assert "archive-token-row11" not in sys.argv[1]' "$OUT" \
  && ok "row 11 list hides payload" || bad "row 11 list hides payload"

# Row 12, fresh db plus row 2 shape.
fresh
shape
must "row 12 export" "$STATE" export-map --map loop
python3 -c '
import json, sys
d = json.loads(sys.argv[1])
assert list(d) == ["g", "stages"]
want = {
    "one": ("Do", "First", [], 1, 2, 3),
    "two": ("Do", "Second", ["one"], 1, 2, 4),
    "parked": ("Park", "Later", [], 1, 1, 1),
}
assert {s["id"] for s in d["stages"]} == set(want)
for s in d["stages"]:
    assert list(s) == ["id", "a", "m", "b", "depends_on", "class", "what"]
    cls, label, deps, a, m, b = want[s["id"]]
    assert s["class"] == cls and s["what"] == label and s["depends_on"] == deps
    assert s["a"] == a and s["m"] == m and s["b"] == b
    assert isinstance(s["depends_on"], list)
' "$OUT" && ok "row 12 keys" || bad "row 12 keys"

# Row 13, fresh db plus row 2 shape.
fresh
shape
expect3 "row 13 slash" "$STATE" stage put --map loop --id "bad/id" --class Do --a 1 --m 1 --b 1 --label Bad
expect3 "row 13 at" "$STATE" stage put --map loop --id "a@b" --class Do --a 1 --m 1 --b 1 --label Bad
expect3 "row 13 dot" "$STATE" stage put --map loop --id "a.b" --class Do --a 1 --m 1 --b 1 --label Bad
[[ "$(sql "SELECT COUNT(*) FROM stages")" == "3" ]] && ok "row 13 stages stay" || bad "row 13 stages stay"
must "row 13 slash key" "$STATE" pulse admit --key "loop/turn" --snippet kept --source loop \
  --time 2026-10-16T00:00:00Z --status user-stated --kind memory
expect3 "row 13 at key" "$STATE" pulse admit --key "a@b" --snippet kept --source loop \
  --time 2026-10-16T00:00:00Z --status user-stated --kind memory
expect3 "row 13 at evidence" "$STATE" harvest add --map loop --stage one --result shipped --evidence "a@b"
[[ "$(sql "SELECT COUNT(*) FROM harvest_rows")" == "0" ]] && ok "row 13 no harvest" || bad "row 13 no harvest"

# Row 14, fresh db plus row 2 shape, failing premflow first on PATH.
fresh
shape
fake="$(mktemp -d)"
printf '%s\n' '#!/bin/sh' 'exit 1' > "$fake/premflow"
chmod +x "$fake/premflow"
if PATH="$fake:/usr/bin:/bin" "$STATE" harvest add --map loop --stage one --result shipped --evidence "merged sha" >/dev/null; then
  ok "row 14 harvest"
else
  bad "row 14 harvest"
fi

# Row 15, fresh db, premflow absent from PATH.
fresh
must "row 15 init" "$STATE" init
must "row 15 map" "$STATE" map put --id loop --g Arrive
must "row 15 one" "$STATE" stage put --map loop --id one --class Do --a 1 --m 2 --b 3 --label First --next 1
must "row 15 two" "$STATE" stage put --map loop --id two --class Do --a 1 --m 2 --b 4 --label Second --depends one
must "row 15 open" "$STATE" block open --map loop --stage one --energy mid --plan "draft the note"
must "row 15 harvest" "$STATE" harvest add --map loop --stage one --result shipped --evidence "merged sha"
expect3 "row 15 empty g" "$STATE" map put --id loop --g ""
[[ "$(sql "SELECT g FROM maps WHERE id='loop'")" == "Arrive" ]] && ok "row 15 g kept" || bad "row 15 g kept"
expect3 "row 15 figure" "$STATE" harvest add --map loop --stage one --result "money 40" --evidence "signpost:continue"
[[ "$(sql "SELECT COUNT(*) FROM harvest_rows")" == "1" ]] && ok "row 15 figure row" || bad "row 15 figure row"
must "row 15 ask" "$STATE" ask admit --ask "A thread needs a look."
expect3 "row 15 ask again" "$STATE" ask admit --ask "A thread needs a look."
must "row 15 close" "$STATE" block close --map loop
must "row 15 archive" "$STATE" pulse archive --source harvest --payload "merged sha"
must "row 15 admit" "$STATE" pulse admit --key loop/turn --snippet shipped --source harvest \
  --time 2026-10-16T03:00:00Z --status tool-verified --kind memory
must "row 15 done" "$STATE" stage put --map loop --id one --class Done --a 1 --m 2 --b 3 --label First
must "row 15 report" "$STATE" apply-report --map loop --critical two --next two
must "row 15 next" "$STATE" next --map loop
python3 -c 'import json,sys; assert json.loads(sys.argv[1])["stage_id"]=="two"' "$OUT" \
  && ok "row 15 stage two" || bad "row 15 stage"

# Path order stays on temp dirs.
pdir="$(mktemp -d)"
if env TSTACK_STATE_DB="$pdir/a.sqlite" PULSE_MEMORY_DB="$pdir/b.sqlite" "$STATE" init >/dev/null; then
  [[ -f "$pdir/a.sqlite" && ! -f "$pdir/b.sqlite" ]] && ok "path TSTACK wins" || bad "path TSTACK wins"
else
  bad "path TSTACK wins"
fi
pdir="$(mktemp -d)"
if env -u TSTACK_STATE_DB PULSE_MEMORY_DB="$pdir/pulse.sqlite" "$STATE" init >/dev/null; then
  [[ -f "$pdir/pulse.sqlite" ]] && ok "path PULSE fallback" || bad "path PULSE fallback"
else
  bad "path PULSE fallback"
fi
xdg="$(mktemp -d)"
xdg_mode="$(mode "$xdg")"
if env -u TSTACK_STATE_DB -u PULSE_MEMORY_DB XDG_DATA_HOME="$xdg" "$STATE" init >/dev/null; then
  [[ -f "$xdg/tstack/state.sqlite" ]] && ok "path xdg file" || bad "path xdg file"
  [[ "$(mode "$xdg/tstack")" == "700" ]] && ok "path xdg dir 700" || bad "path xdg dir"
  [[ "$(mode "$xdg")" == "$xdg_mode" ]] && ok "path xdg parent" || bad "path xdg parent"
  [[ "$(mode "$xdg/tstack/state.sqlite")" == "600" ]] && ok "path xdg mode 600" || bad "path xdg mode"
else
  bad "path xdg"
fi
xdg="$(mktemp -d)"
mkdir "$xdg/tstack"
chmod 755 "$xdg/tstack"
if env -u TSTACK_STATE_DB -u PULSE_MEMORY_DB XDG_DATA_HOME="$xdg" "$STATE" init >/dev/null; then
  [[ "$(mode "$xdg/tstack")" == "755" ]] && ok "path existing dir" || bad "path existing dir"
else
  bad "path existing dir"
fi

echo "---"
[[ "$fail" -eq 0 ]] || { echo "$fail failure(s)"; exit 1; }
echo "ALL CHECKS PASSED"
