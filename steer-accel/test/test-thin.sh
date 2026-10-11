#!/usr/bin/env bash
# Stage loop and the opt-in hook.
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
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
need commands/steer-accel.md
need agents/steer-accel.md
need skills/steer-accel/SKILL.md
need skills/steer-accel/references/steps.md
need bin/steer_accel.py
need bin/steer-accel
need bin/steer-accel-pretool.sh
need hooks/hooks.json
need cursor/hooks/hooks.json

grep -q 'loop.on' "$ROOT/skills/steer-accel/SKILL.md" && ok "marker named" || bad "marker"
grep -q 'coordinator' "$ROOT/skills/steer-accel/SKILL.md" && ok "coordinator arms watch" || bad "coordinator"
grep -q 'steer-log' "$ROOT/skills/steer-accel/SKILL.md" && ok "door stays" || bad "door"
grep -q 'Read|Write|Edit|Bash' "$ROOT/hooks/hooks.json" && ok "hook matcher" || bad "hook matcher"
grep -q 'preToolUse' "$ROOT/cursor/hooks/hooks.json" && ok "cursor write hook" || bad "cursor write hook"
grep -q 'failClosed' "$ROOT/cursor/hooks/hooks.json" && ok "cursor fail closed" || bad "cursor fail closed"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
CHK=(python3 "$ROOT/bin/steer_accel.py")

write_now() {
  cat >"$TMP/now.md" <<EOF
stage: $1
actor: $2
resumed: $3
card: $4
verify: $5
change: ${6:--}
EOF
}

run() {
  local expect=$1
  shift
  set +e
  out=$("${CHK[@]}" "$@" 2>/dev/null)
  rc=$?
  set -e
  if [[ "$rc" -ne "$expect" ]]; then
    bad "$* rc $rc want $expect ($out)"
    return
  fi
  ok "$* → $rc"
}

write_now question builder no INVARIANT.md "pnpm test card"
run 0 check "$TMP/now.md" "$TMP/stage.log"

write_now automate builder no INVARIANT.md "pnpm test card"
run 2 check "$TMP/now.md" "$TMP/stage.log"

printf '%s\n' 'delete | drop the extra pass | pnpm test card' >"$TMP/stage.log"
write_now accelerate builder no INVARIANT.md "pnpm test faster"
run 0 check "$TMP/now.md" "$TMP/stage.log"

write_now accelerate builder no INVARIANT.md "pnpm test card"
printf '%s\n' 'delete | drop the extra pass | pnpm test card' 'accelerate | shorter loop | pnpm test card' >"$TMP/stage.log"
run 2 check "$TMP/now.md" "$TMP/stage.log"

write_now delete coordinator no - "pnpm test card"
run 2 check "$TMP/now.md" "$TMP/stage.log"
write_now delete coordinator no "$TMP/missing-card.md" "pnpm test card"
run 2 check "$TMP/now.md" "$TMP/stage.log"
set +e
out=$("${CHK[@]}" check "$TMP/now.md" "$TMP/stage.log" 2>/dev/null)
set -e
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["reason"]=="coordinator has no invariant card"' "$out" \
  && ok "coordinator missing card" || bad "coordinator missing card ($out)"

# session read required when --reads is set
write_now delete builder yes INVARIANT.md "pnpm test card"
: >"$TMP/reads"
run 2 check "$TMP/now.md" "$TMP/stage.log" --reads "$TMP/reads" --session s1
printf '%s\n' $'s1\tINVARIANT.md' >"$TMP/reads"
run 0 check "$TMP/now.md" "$TMP/stage.log" --reads "$TMP/reads" --session s1
printf '%s\n' $'old\tINVARIANT.md' >"$TMP/reads"
run 2 check "$TMP/now.md" "$TMP/stage.log" --reads "$TMP/reads" --session s1

# append a green row, then the same stage and verify is a stall
cat >"$TMP/card.md" <<'EOF'
# Invariant card
- File creates a draft only on File. Fails: `python3 -c "import sys; sys.exit(1)"`
EOF
GREEN='python3 -c "import sys; sys.exit(0)"'
RED='python3 -c "import sys; sys.exit(1)"'
write_now delete builder no "$TMP/card.md" "$GREEN" "drop the extra pass"
: >"$TMP/stage.log"
run 0 append "$TMP/now.md" "$TMP/stage.log"
run 2 check "$TMP/now.md" "$TMP/stage.log"
set +e
out=$("${CHK[@]}" check "$TMP/now.md" "$TMP/stage.log" 2>/dev/null)
set -e
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["reason"]=="same stage and verify as the last row"' "$out" \
  && ok "green repeat reason" || bad "green repeat reason ($out)"

# red verify blocks the next pass until the card changes, and seven lines still cap it
write_now delete builder no "$TMP/card.md" "$RED" "missed the file press"
: >"$TMP/stage.log"
run 0 append "$TMP/now.md" "$TMP/stage.log"
grep -q '| red |' "$TMP/stage.log" && ok "row records red" || bad "row records red"
run 2 check "$TMP/now.md" "$TMP/stage.log"
set +e
out=$("${CHK[@]}" check "$TMP/now.md" "$TMP/stage.log" 2>/dev/null)
set -e
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["reason"]=="last verify is red and the card is unchanged" and d["next"]=="question"' "$out" \
  && ok "red unchanged" || bad "red unchanged ($out)"
printf '%s\n' '- A bare budget asks per person or total. Fails: `python3 -c "import sys; sys.exit(1)"`' >>"$TMP/card.md"
run 0 check "$TMP/now.md" "$TMP/stage.log"
python3 - "$TMP/card.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
lines = ["# Invariant card"]
for i in range(8):
    lines.append(f"- Rule {i} holds in the product. Fails: `python3 -c \"import sys; sys.exit(1)\"`")
path.write_text("\n".join(lines) + "\n")
PY
run 2 check "$TMP/now.md" "$TMP/stage.log"
set +e
out=$("${CHK[@]}" check "$TMP/now.md" "$TMP/stage.log" 2>/dev/null)
set -e
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["reason"]=="more than seven lines"' "$out" \
  && ok "seven line cap" || bad "seven line cap ($out)"

# hook: quiet without marker, deny without a read, allow after a read
HOOK=(python3 "$ROOT/bin/steer_accel.py" hook)
mkdir -p "$TMP/proj/.steer"
write_now delete builder no INVARIANT.md "pnpm test card"
cp "$TMP/now.md" "$TMP/proj/.steer/now.md"
: >"$TMP/proj/.steer/stage.log"

hook_out() {
  python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["decision"])' <<<"$1"
}

out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"search_replace\",\"toolInput\":{\"file_path\":\"src/app.ts\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "allow" ]] && ok "hook quiet" || bad "hook quiet ($out)"

: >"$TMP/proj/.steer/loop.on"
out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"search_replace\",\"toolInput\":{\"file_path\":\"src/app.ts\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "deny" ]] && ok "hook denies unread write" || bad "hook deny ($out)"

out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"read_file\",\"toolInput\":{\"file_path\":\"INVARIANT.md\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "allow" ]] && ok "hook records read" || bad "hook read ($out)"
grep -q $'s9\tINVARIANT.md' "$TMP/proj/.steer/reads" && ok "read line" || bad "read line"

out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"search_replace\",\"toolInput\":{\"file_path\":\"src/app.ts\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "allow" ]] && ok "hook allows after read" || bad "hook allow ($out)"

out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"search_replace\",\"toolInput\":{\"file_path\":\"$TMP/proj/.steer/now.md\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "allow" ]] && ok "hook allows .steer write" || bad "steer write ($out)"

# coordinator is watched without the marker file
rm -f "$TMP/proj/.steer/loop.on"
write_now delete coordinator no INVARIANT.md "pnpm test card"
cp "$TMP/now.md" "$TMP/proj/.steer/now.md"
out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"search_replace\",\"toolInput\":{\"file_path\":\"src/app.ts\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "deny" ]] && ok "coordinator watch without marker" || bad "coordinator watch ($out)"

# steering doc prose is refused even when the stretch watch is off
write_now delete builder no INVARIANT.md "pnpm test card"
cp "$TMP/now.md" "$TMP/proj/.steer/now.md"
cat >"$TMP/proj/.steer/log.md" <<'EOF'
| decision | why | verify |
| File creates a draft only on File. | A filed draft was sticking to the next brief. | `pnpm test file-press` |
EOF
out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"Write\",\"toolInput\":{\"file_path\":\"notes/steering.md\",\"contents\":\"The last half hour was pixel polish.\\n\\n> File creates a draft only on File.\\n\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "deny" ]] && ok "hook denies steering prose" || bad "steering prose ($out)"
out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"Write\",\"toolInput\":{\"file_path\":\"notes/steering.md\",\"contents\":\"> File creates a draft only on File.\\n\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "allow" ]] && ok "hook allows quote-only steering doc" || bad "quote-only doc ($out)"
out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"sessionId\":\"s9\",\"toolName\":\"bash\",\"toolInput\":{\"command\":\"cat > notes/steering.md <<EOF\\nnarrative\\nEOF\"}}" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "deny" ]] && ok "hook denies hidden steering write" || bad "hidden steering ($out)"

# older log rows cannot be replaced through a write
event=$(python3 - "$TMP/proj" <<'PY'
import json, sys
project = sys.argv[1]
print(json.dumps({
    "cwd": project,
    "sessionId": "s9",
    "toolName": "Write",
    "toolInput": {
        "file_path": project + "/.steer/log.md",
        "contents": "| decision | why | verify |\n| File creates a draft on any click. | rewritten | `pnpm test file-press` |\n",
    },
}))
PY
)
out=$(printf '%s' "$event" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "deny" ]] && ok "hook denies edited log row" || bad "edited log ($out)"
event=$(python3 - "$TMP/proj" <<'PY'
import json, sys
project = sys.argv[1]
print(json.dumps({
    "cwd": project,
    "sessionId": "s9",
    "toolName": "Write",
    "toolInput": {
        "file_path": project + "/.steer/log.md",
        "contents": (
            "| decision | why | verify |\n"
            "| File creates a draft only on File. | A filed draft was sticking to the next brief. | `pnpm test file-press` |\n"
            "| Prices stay in their own currency. | A conversion was a guess. | `pnpm test currency` |\n"
        ),
    },
}))
PY
)
out=$(printf '%s' "$event" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "allow" ]] && ok "hook allows appended log row" || bad "appended log ($out)"
event=$(python3 - "$TMP/proj" <<'PY'
import json, sys
project = sys.argv[1]
print(json.dumps({
    "cwd": project,
    "sessionId": "s9",
    "toolName": "Write",
    "toolInput": {
        "file_path": project + "/.steer/log.md.prior",
        "contents": "rewritten\n",
    },
}))
PY
)
out=$(printf '%s' "$event" | "${HOOK[@]}")
[[ "$(hook_out "$out")" == "deny" ]] && ok "hook denies prior edit" || bad "prior edit ($out)"

# a crash while the watch is on denies; a crash while it is off allows
mkdir -p "$TMP/stub"
printf '%s\n' '#!/bin/sh' 'exit 1' >"$TMP/stub/python3"
chmod +x "$TMP/stub/python3"
: >"$TMP/proj/.steer/loop.on"
set +e
out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"toolName\":\"Write\",\"toolInput\":{\"file_path\":\"src/app.ts\"}}" | PATH="$TMP/stub:$PATH" "$ROOT/bin/steer-accel-pretool.sh")
rc=$?
set -e
[[ "$rc" -eq 2 && "$(hook_out "$out")" == "deny" ]] && ok "armed crash denies" || bad "armed crash rc $rc ($out)"
rm -f "$TMP/proj/.steer/loop.on"
write_now delete builder no INVARIANT.md "pnpm test card"
cp "$TMP/now.md" "$TMP/proj/.steer/now.md"
set +e
out=$(printf '%s' "{\"cwd\":\"$TMP/proj\",\"toolName\":\"Write\",\"toolInput\":{\"file_path\":\"src/app.ts\"}}" | PATH="$TMP/stub:$PATH" "$ROOT/bin/steer-accel-pretool.sh")
rc=$?
set -e
[[ "$rc" -eq 0 && "$(hook_out "$out")" == "allow" ]] && ok "quiet crash allows" || bad "quiet crash rc $rc ($out)"

out=$(python3 - "$ROOT/bin/steer_accel.py" "$TMP/proj" <<'PY'
import importlib.util
import io
import json
import sys
from pathlib import Path

script, project = sys.argv[1], sys.argv[2]
Path(project, ".steer", "loop.on").write_text("")
spec = importlib.util.spec_from_file_location("steer_accel_hook", script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def boom(*_args, **_kwargs):
    raise RuntimeError("boom")

module.evaluate = boom
event = {
    "cwd": project,
    "sessionId": "s9",
    "toolName": "search_replace",
    "toolInput": {"file_path": "src/app.ts"},
}
module.sys.stdin = io.StringIO(json.dumps(event))
module.hook_main()
PY
)
[[ "$(hook_out "$out")" == "deny" ]] && ok "armed exception denies" || bad "armed exception ($out)"

if [[ "$fail" -ne 0 ]]; then
  echo "$fail failed"
  exit 1
fi
echo "ok steer-accel thin"
