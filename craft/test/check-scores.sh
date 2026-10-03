#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 required"
  echo "---"
  exit 1
fi

if ! python3 -c "import pytest" 2>/dev/null; then
  python3 -m pip install --quiet pytest coverage
fi

chmod +x "$ROOT/bin/crap-score.py" "$ROOT/bin/mutation-score.py"

if python3 "$ROOT/bin/crap-score.py" --max 6 \
  "$ROOT/fixtures/good/lib.py" "$ROOT/fixtures/good/test_lib.py"; then
  ok "good fixture CRAP"
else
  bad "good fixture CRAP"
fi

if python3 "$ROOT/bin/mutation-score.py" --min 0.95 \
  "$ROOT/fixtures/good/lib.py" "$ROOT/fixtures/good/test_lib.py"; then
  ok "good fixture mutation"
else
  bad "good fixture mutation"
fi

if python3 "$ROOT/bin/crap-score.py" --max 6 \
  "$ROOT/fixtures/bad-crap/lib.py" "$ROOT/fixtures/bad-crap/test_lib.py"; then
  bad "bad-crap should fail CRAP"
else
  ok "bad-crap fails CRAP"
fi

if python3 "$ROOT/bin/mutation-score.py" --min 0.95 \
  "$ROOT/fixtures/bad-mutants/lib.py" "$ROOT/fixtures/bad-mutants/test_lib.py"; then
  bad "bad-mutants should fail mutation"
else
  ok "bad-mutants fails mutation"
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL SCORE CHECKS PASSED"
exit 0
