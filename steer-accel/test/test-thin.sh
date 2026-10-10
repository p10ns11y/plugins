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

grep -q 'loop.on' "$ROOT/skills/steer-accel/SKILL.md" && ok "opt-in named" || bad "opt-in"
grep -q 'steer-log' "$ROOT/skills/steer-accel/SKILL.md" && ok "door stays" || bad "door"
grep -q 'Read|Write|Edit|Bash' "$ROOT/hooks/hooks.json" && ok "hook matcher" || bad "hook matcher"

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

if [[ "$fail" -ne 0 ]]; then
  echo "$fail failed"
  exit 1
fi
echo "ok steer-accel thin"
