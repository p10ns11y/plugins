#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

is_test_path() {
  local p="${1//\\//}"
  local base
  base="$(basename "$p")"
  [[ "$p" =~ (^|/)tests?/ ]] && return 0
  [[ "$base" == test_*.py ]] && return 0
  [[ "$base" == *_test.py ]] && return 0
  [[ "$base" =~ \.(spec|test)\. ]] && return 0
  return 1
}

is_production_path() {
  local p="$1"
  [[ "$p" =~ \.(py|js|ts|go|rs|c|cpp)$ ]] || return 1
  is_test_path "$p" && return 1
  return 0
}

is_acceptance_path() {
  local p="${1//\\//}"
  [[ "$p" == *.feature ]] && return 0
  [[ "$p" == *features/* || "$p" == *qa/* ]] && return 0
  [[ "$(echo "$p" | tr '[:upper:]' '[:lower:]')" == *acceptance* ]] && return 0
  return 1
}

check_range() {
  local range="$1"
  local accept_seen=0
  local saw_prod=0
  local commit files
  while IFS= read -r commit; do
    [[ -z "$commit" ]] && continue
    files="$(git show --pretty=format: --name-only "$commit")"
    local has_accept=0 has_prod=0
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      if is_acceptance_path "$f"; then has_accept=1; fi
      if is_production_path "$f"; then has_prod=1; saw_prod=1; fi
    done <<< "$files"
    if [[ "$has_accept" -eq 1 ]]; then accept_seen=1; fi
    if [[ "$has_prod" -eq 1 && "$accept_seen" -eq 0 ]]; then
      echo "production before acceptance in commit $commit"
      return 1
    fi
  done < <(git log --reverse --format=%H "$range")
  if [[ "$saw_prod" -eq 1 && "$accept_seen" -eq 0 ]]; then
    echo "production without acceptance in $range"
    return 1
  fi
  return 0
}

run_temp_repo() {
  local dir
  dir="$(mktemp -d "${TMPDIR:-/tmp}/craft-accept.XXXXXX")"
  git -C "$dir" init -q
  git -C "$dir" config user.email craft@test
  git -C "$dir" config user.name craft
  printf '%s\n' "$dir"
}

fixture="$ROOT/fixtures/acceptance-good"
[[ -f "$fixture/features/login.feature" ]] && ok "fixture gherkin" || bad "fixture gherkin"
[[ -f "$fixture/qa/login.md" ]] && ok "fixture qa" || bad "fixture qa"

pass_dir="$(run_temp_repo)"
(
  cd "$pass_dir"
  mkdir -p features
  printf 'Feature: A\n' > features/first.feature
  git add features/first.feature
  git commit -qm acc
  printf 'x = 1\n' > contest.py
  git add contest.py
  git commit -qm prod
)
if (cd "$pass_dir" && check_range HEAD); then
  ok "temp repo acceptance first passes"
else
  bad "temp repo acceptance first should pass"
fi
rm -rf "$pass_dir"

fail_dir="$(run_temp_repo)"
(
  cd "$fail_dir"
  printf 'x = 1\n' > lib.py
  git add lib.py
  git commit -qm prod
  mkdir -p features
  printf 'Feature: B\n' > features/late.feature
  git add features/late.feature
  git commit -qm acc
)
if (cd "$fail_dir" && check_range HEAD); then
  bad "temp repo coder first should fail"
else
  ok "temp repo coder first fails"
fi
rm -rf "$fail_dir"

same_dir="$(run_temp_repo)"
(
  cd "$same_dir"
  mkdir -p features
  printf 'Feature: C\n' > features/together.feature
  printf 'y = 2\n' > module.py
  git add features/together.feature module.py
  git commit -qm both
)
if (cd "$same_dir" && check_range HEAD); then
  ok "temp repo same commit passes"
else
  bad "temp repo same commit should pass"
fi
rm -rf "$same_dir"

if [[ "${1:-}" == "--self" || $# -eq 0 ]]; then
  echo "---"
  if [[ "$fail" -ne 0 ]]; then
    echo "$fail failure(s)"
    exit 1
  fi
  echo "ALL ACCEPTANCE CHECKS PASSED"
  exit 0
fi

range="$1"
if check_range "$range"; then
  ok "range $range acceptance order"
else
  bad "range $range production before acceptance"
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL ACCEPTANCE CHECKS PASSED"
exit 0
