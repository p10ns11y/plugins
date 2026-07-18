#!/usr/bin/env bash
# Dual-launch: expand without consent fails; with --yes --dry-run succeeds twice.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GROK_PLUGIN_ROOT="$ROOT"
EXPAND="$ROOT/bin/am-expand"
chmod +x "$EXPAND" "$ROOT/bin/"*

echo "=== launch 1: no consent ==="
set +e
out1=$("$EXPAND" security 2>&1)
ec1=$?
set -e
echo "$out1"
[[ "$ec1" -eq 2 ]] || { echo "expected exit 2"; exit 1; }
echo "$out1" | grep -q consent_required

echo "=== launch 2: dry-run with consent ==="
out2=$("$EXPAND" security --yes --dry-run 2>&1)
echo "$out2"
echo "$out2" | grep -q 'dry-run'
echo "$out2" | grep -q security

echo "=== launch 3: second dry-run consistent ==="
out3=$("$EXPAND" ml-dev --yes --dry-run 2>&1)
echo "$out3"
echo "$out3" | grep -q 'dry-run'
echo "$out3" | grep -q ml-dev

echo "=== unknown tier ==="
set +e
"$EXPAND" totally-fake --yes --dry-run
ec=$?
set -e
[[ "$ec" -eq 2 ]]

echo "EXPAND_CONSENT_OK"
