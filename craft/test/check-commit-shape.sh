#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }
good=$'pager: clamp last page\n\nWhy: last page was empty\nWhat: clamp index\nProof: tests/test_pager.py passes'
repo() {
  local d
  d="$(mktemp -d)"
  git -C "$d" init -q -b main
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
  (cd "$d" && "$ROOT/bin/check-commit-shape.sh" "$(git rev-list --max-parents=0 HEAD)..HEAD" >/dev/null 2>&1) || got=fail
  rm -rf "$d"
  [[ "$got" == "$want" ]] && ok "$name" || bad "$name wanted $want got $got"
}
d="$(repo)"; put "$d" "$good" src/pager.py tests/test_pager.py
expect one-change-full-message pass "$d"
d="$(repo)"; put "$d" $'pager\n\nWhy: x\nWhat: y' src/pager.py
expect missing-proof fail "$d"
d="$(repo)"; put "$d" "pager" src/pager.py
expect missing-why-what-proof fail "$d"
d="$(repo)"; put "$d" "$good" src/pager.py billing/invoice.py
expect two-changes-one-commit fail "$d"
d="$(repo)"; put "$d" "${good/pager: clamp last page/docs: pager notes}" README.md
expect docs-only pass "$d"
d="$(repo)"; git -C "$d" switch -q -c side; put "$d" "$good" src/pager.py; git -C "$d" switch -q main; put "$d" "$good" src/list.py
git -C "$d" merge -q --no-ff side -m "$good"
expect merge-commit fail "$d"
echo "---"
if [[ "$fail" -ne 0 ]]; then echo "$fail failure(s)"; exit 1; fi
echo "ALL COMMIT SHAPE CHECKS PASSED"
