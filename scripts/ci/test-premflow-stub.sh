#!/usr/bin/env bash
# Check the test stub, then the missing-CLI path. The narrow PATH is only the missing-CLI check.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STUB="$ROOT/scripts/ci/premflow"
RESOLVE="$ROOT/premflow/bin/pf-resolve"

out="$("$STUB" pomo 25 note)"
[[ "$out" == *"[POMO]"* ]] || {
  echo "stdout missing [POMO]: $out" >&2
  exit 1
}
[[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" == "1" ]] || {
  echo "pomo should print one line: $out" >&2
  exit 1
}

"$STUB" task add
"$STUB" task done
"$STUB" win

set +e
hint="$(
  unset PREMFLOW_BIN
  export PATH=/usr/bin:/bin
  if command -v premflow >/dev/null 2>&1; then
    echo "premflow still on the narrow PATH" >&2
    exit 3
  fi
  "$RESOLVE" 2>&1 >/dev/null
)"
ec=$?
set -e
[[ "$ec" -eq 1 ]] || {
  echo "expected pf-resolve exit 1 when the CLI is missing, got $ec" >&2
  exit 1
}
[[ "$hint" == *"premflow CLI not found on PATH."* ]] || {
  echo "install hint missing from stderr: $hint" >&2
  exit 1
}

got="$(PREMFLOW_BIN="$STUB" "$RESOLVE")"
[[ "$got" == "$STUB" ]] || {
  echo "expected $STUB, got $got" >&2
  exit 1
}

echo "PREMFLOW_STUB_OK"
