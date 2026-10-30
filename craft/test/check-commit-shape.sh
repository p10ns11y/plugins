#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib-ub.sh"
CHECK="$ROOT/bin/check-commit-shape.sh"
good=$'pager: clamp last page\n\nWhy: last page was empty\nWhat: clamp index\nProof: tests/test_pager.py passes'
d="$(repo)"; put "$d" "$good" src/pager.py tests/test_pager.py
expect one-change-full-message pass "$d"
d="$(repo)"; put "$d" $'pager\n\nWhy: x\nWhat: y' src/pager.py
expect missing-proof fail "$d"
d="$(repo)"; put "$d" "pager" src/pager.py
expect missing-why-what-proof fail "$d"
d="$(repo)"; put "$d" "$good" src/pager.py lib/module.py
expect two-changes-one-commit fail "$d"
d="$(repo)"; put "$d" "${good/pager: clamp last page/docs: pager notes}" README.md
expect docs-only pass "$d"
d="$(repo)"; git -C "$d" switch -q -c side; put "$d" "$good" src/pager.py; git -C "$d" switch -q main; put "$d" "$good" src/list.py
git -C "$d" merge -q --no-ff side -m "$good"
expect merge-commit fail "$d"
finish "COMMIT SHAPE"
