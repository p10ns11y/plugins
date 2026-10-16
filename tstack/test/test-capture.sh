#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/bin/capture-sweep"
FIX="$ROOT/test/fixtures/capture"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

expect_card() {
  local name="$1" file="$2" expect="$3" out
  if out="$("$BIN" emit "$file" 2>"$TMP/err")"; then
    if [[ "$out" == "$expect" ]]; then ok "$name"; else bad "$name output"; printf '%s\n' "$out" >&2; fi
  else
    bad "$name exit"
  fi
}

read_expect() {
  expect_card "$1" "$FIX/$2" "$(cat <<EOF
# Card
- kind: $3
- source: $4
- ask: $5
- deadline: $6
- holds: $7
- owner: $8
- ref: $9
EOF
)"
}

read_expect mail-none mail-none.txt none mail "A thread needs a look." none none none mail:1
read_expect calendar-none calendar-none.txt none calendar "A calendar block changed." 2026-10-16 none none calendar:3
read_expect chat-none chat-none.txt none chat "A chat needs a look." none none none chat:4
read_expect mail-send mail-send.txt send mail "A note is waiting to go out." none send si mail:2
read_expect calendar-money calendar-money.txt money calendar "A bill needs a human decision." none pay si calendar:5
read_expect pr-sign pr-sign.txt sign pr "A document needs signing." none sign si pr:6

if "$BIN" emit "$FIX/bad-digit.txt" >"$TMP/out" 2>"$TMP/err"; then
  bad "digit ask should fail"
else
  [[ ! -s "$TMP/out" ]] && ok "digit ask silent" || bad "digit ask printed"
fi

cat >"$TMP/at.txt" <<'EOF'
source: mail
kind: none
ask: Ping a@b now.
deadline: none
owner: none
holds: none
ref: mail:9
EOF
if "$BIN" emit "$TMP/at.txt" >"$TMP/out" 2>"$TMP/err"; then
  bad "at ask should fail"
else
  [[ ! -s "$TMP/out" ]] && ok "at ask silent" || bad "at ask printed"
fi

cat >"$TMP/http.txt" <<'EOF'
source: mail
kind: none
ask: Open http now.
deadline: none
owner: none
holds: none
ref: mail:9
EOF
if "$BIN" emit "$TMP/http.txt" >"$TMP/out" 2>"$TMP/err"; then
  bad "http ask should fail"
else
  [[ ! -s "$TMP/out" ]] && ok "http ask silent" || bad "http ask printed"
fi

cat >"$TMP/lie.txt" <<'EOF'
source: mail
kind: money
ask: A bill needs a human decision.
deadline: none
owner: none
holds: none
ref: mail:8
EOF
if "$BIN" emit "$TMP/lie.txt" >"$TMP/out" 2>"$TMP/err"; then
  bad "lie should fail"
else
  [[ ! -s "$TMP/out" ]] && ok "lie refused" || bad "lie printed"
fi

if "$BIN" check-allows >/dev/null; then
  ok "allows"
else
  bad "allows"
fi

mkdir -p "$TMP/bad"
printf '%s\n' list get search >"$TMP/bad/mail.allow"
printf '%s\n' list get search >"$TMP/bad/calendar.allow"
printf '%s\n' list >"$TMP/bad/pr.allow"
printf '%s\n' send >"$TMP/bad/chat.allow"
if CAPTURE_ALLOWS="$TMP/bad" "$BIN" check-allows >"$TMP/out" 2>"$TMP/err"; then
  bad "denied token should fail"
else
  ok "denied token"
fi

echo "---"
[[ "$fail" -eq 0 ]] || { echo "$fail failure(s)"; exit 1; }
echo "CAPTURE CHECKS PASSED"
