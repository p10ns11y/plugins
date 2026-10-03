#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

fixture="$ROOT/fixtures/acceptance-good"
[[ -f "$fixture/features/login.feature" ]] && ok "fixture gherkin" || bad "fixture gherkin"
[[ -f "$fixture/qa/login.md" ]] && ok "fixture qa" || bad "fixture qa"

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
prod=$(git diff --name-only "$range" | grep -E '\.(py|js|ts|go|rs|c|cpp)$' | grep -v test | grep -v spec || true)
accept=$(git diff --name-only "$range" | grep -E '(\.feature$|/qa/|/features/|acceptance)' || true)
if [[ -z "$prod" ]]; then
  ok "no production diff in range"
else
  if [[ -n "$accept" ]]; then
    ok "acceptance files present with production diff"
  else
    bad "production diff without acceptance files in $range"
  fi
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL ACCEPTANCE CHECKS PASSED"
exit 0
