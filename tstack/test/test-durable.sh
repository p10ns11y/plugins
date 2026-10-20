#!/usr/bin/env bash
# Step journal, resume, effect keys, stale blocks, PR triage.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
S="$ROOT/scripts/tstack-state"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }
j() { python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(eval(sys.argv[2]))" "$1" "$2"; }
dir="$(mktemp -d)"
export TSTACK_STATE_DB="$dir/state.sqlite"
"$S" init >/dev/null
"$S" map put --id m --g "ship c1" >/dev/null
"$S" stage put --map m --id c1 --class Do --a 1 --m 2 --b 3 --label "chunk one" >/dev/null
"$S" block open --map m --stage c1 --energy high >/dev/null

out="$("$S" step start --map m --stage c1 --step verify)"
sid="$(j "$out" 'd["id"]')"
[[ "$(j "$out" 'd["resumed"]')" == "False" ]] && ok "step start new" || bad "step start new"
out="$("$S" resume --map m)"
[[ "$(j "$out" 'len(d["unfinished_steps"])')" == "1" ]] && ok "resume shows running step" || bad "resume running"
out="$("$S" step start --map m --stage c1 --step verify)"
[[ "$(j "$out" 'd["id"]')" == "$sid" && "$(j "$out" 'd["resumed"]')" == "True" ]] && ok "restart resumes same row" || bad "restart resumes"
"$S" step end --id "$sid" --status ok >/dev/null
out="$("$S" step end --id "$sid" --status ok)"
[[ "$(j "$out" 'd["duplicate"]')" == "True" ]] && ok "step end twice no-op" || bad "step end twice"
out="$("$S" resume --map m)"
[[ "$(j "$out" 'len(d["unfinished_steps"])')" == "0" ]] && ok "resume clear after end" || bad "resume clear"
"$S" step end --id "$sid" --status bogus >/dev/null 2>&1 && bad "bad status accepted" || ok "bad status rejected"

out="$("$S" effect check --key c1:abc:push)"
[[ "$(j "$out" 'd["done"]')" == "False" ]] && ok "effect not done" || bad "effect not done"
out="$("$S" effect record --key c1:abc:push --kind push --ref abc)"
[[ "$(j "$out" 'd["duplicate"]')" == "False" ]] && ok "effect record" || bad "effect record"
out="$("$S" effect record --key c1:abc:push --kind push --ref abc)"
[[ "$(j "$out" 'd["duplicate"]')" == "True" ]] && ok "effect repeat no-op" || bad "effect repeat"
out="$("$S" effect check --key c1:abc:push)"
[[ "$(j "$out" 'd["done"]')" == "True" ]] && ok "effect done" || bad "effect done"
n="$(python3 -c "import sqlite3,sys; print(sqlite3.connect(sys.argv[1]).execute('select count(*) from effects').fetchone()[0])" "$TSTACK_STATE_DB")"
[[ "$n" == "1" ]] && ok "one effect row" || bad "effect rows $n"

a="$("$S" harvest add --map m --stage c1 --result shipped --evidence sha1 --key c1:sha1:harvest)"
b="$("$S" harvest add --map m --stage c1 --result shipped --evidence sha1 --key c1:sha1:harvest)"
[[ "$(j "$a" 'd["id"]')" == "$(j "$b" 'd["id"]')" && "$(j "$b" 'd["duplicate"]')" == "True" ]] && ok "harvest key no-op" || bad "harvest key"
"$S" harvest add --map m --stage c1 --result shipped --evidence sha1 >/dev/null && ok "harvest without key" || bad "harvest without key"

# stale block: age the heartbeat, then a new open is flagged with the id.
python3 -c "import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(\"update blocks set started_at='2026-01-01T00:00:00Z', heartbeat_at='2026-01-01T00:00:00Z'\"); c.commit()" "$TSTACK_STATE_DB"
set +e; out="$("$S" block open --map m --stage c1 --energy mid)"; rc=$?; set -e
[[ "$rc" == "3" && "$(j "$out" 'd["error"]')" == "stale open block" ]] && ok "stale block flagged" || bad "stale block $rc $out"
out="$("$S" resume --map m)"
[[ "$(j "$out" 'd["open_blocks"][0]["stale"]')" == "True" ]] && ok "resume marks stale" || bad "resume stale"
"$S" block beat --map m >/dev/null
set +e; out="$("$S" block open --map m --stage c1 --energy mid)"; rc=$?; set -e
[[ "$rc" == "3" && "$(j "$out" 'd["error"]')" == "second open block" ]] && ok "beat makes it live" || bad "beat live $out"

# triage
out="$(TRIAGE_NOW=2026-10-20T12:00:00Z "$ROOT/bin/pr-triage" --file "$ROOT/test/fixtures/triage/prs.json" | python3 -c 'import json,sys; print(",".join(json.loads(l)["state"] for l in sys.stdin))')"
want="blocked-on-user,resume,resume,blocked-on-party,blocked-on-party,propose-close,resume"
[[ "$out" == "$want" ]] && ok "triage states" || bad "triage $out"
ask="$(TRIAGE_NOW=2026-10-20T12:00:00Z "$ROOT/bin/pr-triage" --file "$ROOT/test/fixtures/triage/prs.json" | sed -n 4p)"
[[ "$ask" == *"ask one yes/no now"* ]] && ok "silent draft asks after 72h" || bad "silent draft $ask"
out="$(FROZEN=1 TRIAGE_NOW=2026-10-20T12:00:00Z "$ROOT/bin/pr-triage" --file "$ROOT/test/fixtures/triage/prs.json" | grep -c blocked-on-user)"
[[ "$out" == "7" ]] && ok "frozen repo all on user" || bad "frozen $out"

# install
bin="$(mktemp -d)"
TSTACK_STATE_DB="$dir/i.sqlite" bash "$ROOT/scripts/install.sh" "$bin" >/dev/null 2>&1
[[ -x "$bin/tstack-state" && -f "$dir/i.sqlite" ]] && ok "install links and inits" || bad "install"

echo "---"
[[ "$fail" -eq 0 ]] || { echo "$fail failure(s)"; exit 1; }
echo "ALL CHECKS PASSED"
