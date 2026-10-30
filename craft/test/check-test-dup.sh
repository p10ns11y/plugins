#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
out="$("$ROOT/bin/dup-ratio" --limit 0.03 "$ROOT/test/check-red-commit.sh" "$ROOT/test/check-dup-ratio.sh" "$ROOT/test/check-commit-shape.sh")" && { echo "ok  $out"; echo "ALL TEST DUPLICATION CHECKS PASSED"; } || { echo "FAIL $out"; exit 1; }
