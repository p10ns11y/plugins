#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }
repo() {
  local d
  d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" config user.email craft
  git -C "$d" config user.name craft
  git -C "$d" config commit.gpgsign false
  git -C "$d" commit -q --allow-empty -m base
  echo "$d"
}
put() {
  local d="$1" msg="$2" f
  shift 2
  for f in "$@"; do mkdir -p "$d/$(dirname "$f")"; echo "$f $RANDOM" >> "$d/$f"; done
  git -C "$d" add -A
  git -C "$d" commit -qm "$msg"
}
expect() {
  local name="$1" want="$2" d="$3" got=pass
  (cd "$d" && "$ROOT/bin/check-red-commit.sh" "$(git rev-list --max-parents=0 HEAD)..HEAD" >/dev/null 2>&1) || got=fail
  rm -rf "$d"
  [[ "$got" == "$want" ]] && ok "$name" || bad "$name wanted $want got $got"
}
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
echo "---"
if [[ "$fail" -ne 0 ]]; then echo "$fail failure(s)"; exit 1; fi
echo "ALL RED COMMIT CHECKS PASSED"
