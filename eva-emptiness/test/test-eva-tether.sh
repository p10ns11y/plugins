#!/usr/bin/env sh
# test-eva-tether.sh — classifier smoke tests (C + shell fallback)
set -eu
# shellcheck disable=SC3040
(set -o pipefail) 2>/dev/null && set -o pipefail

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
BIN="$ROOT/bin/eva-tether"
PRE="$ROOT/bin/eva-tether-pretool.sh"
CUR="$ROOT/cursor/hooks/eva-tether-shell.sh"
fail=0

assert_contains() {
  _hay=$1
  _needle=$2
  _label=$3
  case $_hay in
    *"$_needle"*) echo "ok $_label" ;;
    *)
      echo "FAIL $_label"
      echo "  expected substring: $_needle"
      echo "  got: $_hay"
      fail=1
      ;;
  esac
}

assert_empty() {
  _hay=$1
  _label=$2
  if [ -z "$_hay" ]; then
    echo "ok $_label"
  else
    echo "FAIL $_label (expected empty)"
    echo "  got: $_hay"
    fail=1
  fi
}

run_c() {
  _mode=$1
  _in=$2
  printf '%s' "$_in" | "$BIN" --mode="$_mode"
}

run_shell_pre() {
  # Force shell path by hiding C via PATH and temp rename if present
  printf '%s' "$1" | EVA_TETHER_FORCE_SHELL=1 sh -c '
    ROOT="'"$ROOT"'"
    # Invoke shell include directly
    EVA_TETHER_MODE=grok
    export EVA_TETHER_MODE
    . "$ROOT/bin/eva-tether-shell.inc"
    eva_tether_shell_main
  '
}

echo "=== build C ==="
if [ ! -x "$BIN" ]; then
  make -C "$ROOT/c" all
fi
test -x "$BIN" || { echo "FAIL: no binary"; exit 1; }
chmod +x "$PRE" "$CUR" "$ROOT/bin/eva-tether-build" 2>/dev/null || true

echo "=== C grok mode ==="
out=$(run_c grok '{"toolInput":"git push origin main"}')
assert_contains "$out" '"decision":"deny"' "c grok git push deny"
assert_contains "$out" 'git push' "c grok git push reason"

out=$(run_c grok '{"toolInput":"git push --force origin main"}')
assert_contains "$out" 'force-push' "c grok force-push"

out=$(run_c grok '{"toolInput":"git reset --hard HEAD"}')
assert_contains "$out" 'reset --hard' "c grok reset hard"

out=$(run_c grok '{"toolInput":"agent --yolo"}')
assert_contains "$out" 'always-approve/yolo' "c grok yolo"

out=$(run_c grok '{"toolInput":"rm -rf /"}')
assert_contains "$out" 'recursive delete' "c grok rm root"

out=$(run_c grok '{"toolInput":"echo hello"}')
assert_empty "$out" "c grok allow empty"

echo "=== C cursor mode ==="
out=$(run_c cursor '{"command":"git push origin main"}')
assert_contains "$out" '"permission":"ask"' "c cursor git push ask"

out=$(run_c cursor '{"command":"git push -f origin main"}')
assert_contains "$out" '"permission":"deny"' "c cursor force deny"

out=$(run_c cursor '{"command":"ls"}')
assert_contains "$out" '"permission":"allow"' "c cursor allow"

echo "=== shell fallback grok ==="
out=$(run_shell_pre '{"toolInput":"git push origin main"}')
assert_contains "$out" '"decision":"deny"' "shell grok git push"

out=$(run_shell_pre '{"toolInput":"echo hi"}')
assert_empty "$out" "shell grok allow"

echo "=== entry scripts (C preferred) ==="
out=$(printf '%s' '{"toolInput":"git push"}' | "$PRE")
assert_contains "$out" 'deny' "pretool git push"

out=$(printf '%s' '{"command":"git push"}' | "$CUR")
assert_contains "$out" 'ask' "cursor shell git push ask"

echo "=== build status (no consent) ==="
if "$ROOT/bin/eva-tether-build" --status >/dev/null; then
  echo "ok build status"
else
  echo "FAIL build status"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "ALL PASS"
exit 0
