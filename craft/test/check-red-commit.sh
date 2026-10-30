#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib-ub.sh"
CHECK="$ROOT/bin/check-red-commit.sh"
d="$(repo)"; put "$d" "add pager" src/pager.py; put "$d" "test pager" tests/test_pager.py
expect source-before-test fail "$d"
d="$(repo)"; put "$d" $'test pager\n\nRed-run: FAILED (failures=1)' tests/test_pager.py; put "$d" "add pager" src/pager.py
expect test-only-red-log pass "$d"
d="$(repo)"; put "$d" "test pager" tests/test_pager.py; put "$d" "add pager" src/pager.py
expect test-without-red-log fail "$d"
d="$(repo)"; put "$d" $'test pager\n\nRed-run: OK' tests/test_pager.py; put "$d" "add pager" src/pager.py
expect red-log-not-failing fail "$d"
d="$(repo)"; put "$d" $'pager and test\n\nRed-run: FAILED' tests/test_pager.py src/pager.py
expect test-and-source-together fail "$d"
d="$(repo)"; put "$d" "docs" README.md
expect no-source pass "$d"
finish "RED COMMIT"
