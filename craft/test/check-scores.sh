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

if ! python3 -c "import pytest, coverage" 2>/dev/null; then
  python3 -m pip install --quiet pytest coverage
fi

chmod +x "$ROOT/bin/"*.py
export PYTHONPATH="$ROOT/bin${PYTHONPATH:+:$PYTHONPATH}"

if python3 "$ROOT/bin/crap-score.py" --max 6 \
  "$ROOT/fixtures/good/lib.py" "$ROOT/fixtures/good/test_lib.py" | grep -q '^scope=file'; then
  ok "good CRAP scope=file"
else
  bad "good CRAP missing scope=file"
fi

if python3 "$ROOT/bin/crap-score.py" --max 6 \
  "$ROOT/fixtures/good/lib.py" "$ROOT/fixtures/good/test_lib.py"; then
  ok "good fixture CRAP"
else
  bad "good fixture CRAP"
fi

if python3 "$ROOT/bin/mutation-score.py" --min 0.95 \
  "$ROOT/fixtures/good/lib.py" "$ROOT/fixtures/good/test_lib.py" | grep -q '^scope=file'; then
  ok "good mutation scope=file"
else
  bad "good mutation missing scope=file"
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

if python3 "$ROOT/bin/crap-score.py" --max 6 \
  "$ROOT/fixtures/bad-split-cov/lib.py" "$ROOT/fixtures/bad-split-cov/test_lib.py"; then
  bad "bad-split-cov should fail CRAP"
else
  ok "bad-split-cov fails CRAP"
fi

if python3 "$ROOT/bin/mutation-score.py" --min 0.95 \
  "$ROOT/fixtures/bad-mutants/lib.py" "$ROOT/fixtures/bad-mutants/test_lib.py"; then
  bad "bad-mutants should fail mutation"
else
  ok "bad-mutants fails mutation"
fi

if python3 "$ROOT/bin/crap-score.py" --max 6 --functions uncovered \
  "$ROOT/fixtures/bad-split-cov/lib.py" "$ROOT/fixtures/bad-split-cov/test_lib.py" 2>/dev/null; then
  bad "scoped uncovered should fail CRAP"
else
  ok "scoped uncovered fails CRAP"
fi

if python3 -c "
import importlib.util, subprocess, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location('sl', Path('$ROOT/bin/score_lib.py'))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
orig = __import__('builtins').__import__
def fake(name, *a, **k):
    if name == 'coverage':
        raise ImportError('no')
    return orig(name, *a, **k)
import builtins
builtins.__import__ = fake
try:
    mod.require_coverage()
except SystemExit as e:
    sys.exit(0 if e.code == 2 else 1)
sys.exit(1)
" 2>/dev/null; then
  ok "missing coverage errors"
else
  bad "missing coverage should exit 2"
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL SCORE CHECKS PASSED"
exit 0
