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

mkdir -p "$TMP/nobin" "$TMP/ghbin"
ln -s "$(command -v bash)" "$TMP/nobin/bash"
ln -s "$(command -v bash)" "$TMP/ghbin/bash"
ln -s "$(command -v python3)" "$TMP/ghbin/python3"
if env PATH="$TMP/nobin" "$BIN" live-pr >"$TMP/out" 2>"$TMP/err"; then
  [[ ! -s "$TMP/out" ]] && grep -qx 'pr: unavailable' "$TMP/err" && ok "pr missing" || bad "pr missing output"
else
  bad "pr missing exit"
fi

cat >"$TMP/ghbin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${GH_LOG:?}"
[[ "$*" == "pr list --json number,title,updatedAt --limit 20" ]] || exit 9
if [[ -n "${GH_EXIT:-}" ]]; then
  printf '%s\n' "${GH_NOISE:-}" >&2
  exit "$GH_EXIT"
fi
printf '%s' "${GH_JSON:?}"
EOF
chmod +x "$TMP/ghbin/gh"
export GH_LOG="$TMP/gh.log"
export GH_JSON='[{"number":7,"title":"Zebraunique","updatedAt":"2026-10-16T01:02:03Z"}]'
out="$(env PATH="$TMP/ghbin" GH_LOG="$GH_LOG" GH_JSON="$GH_JSON" "$BIN" live-pr)"
[[ "$out" == "$(cat <<'EOF'
# Card
- kind: none
- source: pr
- ask: A pull request is waiting.
- deadline: 2026-10-16
- holds: none
- owner: none
- ref: pr:7
EOF
)" ]] && ok "live pr" || bad "live pr"
[[ "$out" != *Zebraunique* ]] && ok "title dropped" || bad "title leaked"
[[ "$(cat "$GH_LOG")" == "pr list --json number,title,updatedAt --limit 20" ]] && ok "argv" || bad "argv"

if env PATH="$TMP/ghbin" GH_LOG="$GH_LOG" GH_JSON='[]' GH_EXIT=1 GH_NOISE=NOTACARD "$BIN" live-pr >"$TMP/out" 2>"$TMP/err"; then
  [[ ! -s "$TMP/out" ]] && grep -qx 'pr: unavailable' "$TMP/err" && ! grep -q NOTACARD "$TMP/err" && ok "pr fail" || bad "pr fail output"
else
  bad "pr fail exit"
fi

export GH_JSON='[{"number":8,"title":"Zebraunique","updatedAt":"not-a-date"}]'
out="$(env PATH="$TMP/ghbin" GH_LOG="$GH_LOG" GH_JSON="$GH_JSON" "$BIN" live-pr)"
[[ "$out" == *"- deadline: none"* && "$out" == *"- ref: pr:8"* ]] && ok "bad date" || bad "bad date"

: >"$GH_LOG"
env PATH="$TMP/ghbin" GH_LOG="$GH_LOG" GH_JSON='[]' "$BIN" emit "$FIX/mail-none.txt" >/dev/null
[[ ! -s "$GH_LOG" ]] && ok "emit skips gh" || bad "emit called gh"

echo "---"
[[ "$fail" -eq 0 ]] || { echo "$fail failure(s)"; exit 1; }
echo "CAPTURE CHECKS PASSED"
