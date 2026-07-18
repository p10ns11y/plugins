#!/usr/bin/env bash
# Unit tests for core-map parse + consent gate (no network).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GROK_PLUGIN_ROOT="$ROOT"
# shellcheck source=../bin/am-lib.sh
source "$ROOT/bin/am-lib.sh"

fail=0
assert_eq() {
  local got="$1" want="$2" msg="$3"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL $msg: got='$got' want='$want'" >&2
    fail=1
  else
    echo "ok $msg"
  fi
}

assert_ok() {
  if "$@"; then echo "ok $*"; else echo "FAIL $*"; fail=1; fi
}
assert_fail() {
  if "$@"; then echo "FAIL expected fail: $*"; fail=1; else echo "ok fail closed: $*"; fi
}

echo "=== core-map parse ==="
assert_eq "$(am_map_get '.policy.default_install')" "thin" "default_install=thin"
assert_eq "$(am_map_get '.core.tier')" "thin" "core.tier=thin"
assert_ok am_is_core_binary tinfoil
assert_ok am_is_expandable security
assert_ok am_is_expandable ml-dev
assert_fail am_is_expandable not-a-real-tier

echo "=== FSD allowlist ==="
assert_ok am_fsd_allowed status
assert_ok am_fsd_allowed audit
assert_fail am_fsd_allowed expand
assert_ok am_requires_consent expand
assert_ok am_requires_consent init

echo "=== consent gate ==="
set +e
am_consent_gate expand
ec=$?
set -e
assert_eq "$ec" "2" "expand without --yes exits 2"

set +e
am_consent_gate expand --yes
ec=$?
set -e
assert_eq "$ec" "0" "expand with --yes ok"

set +e
am_consent_gate init
ec=$?
set -e
assert_eq "$ec" "2" "init without --yes exits 2"

assert_ok am_fsd_allowed map
assert_eq "$(am_map_get '.policy.fail_closed_without_consent|tostring')" "true" "fail_closed"

# ISP policy present
assert_eq "$(am_map_get '.policy.public_isp_ip_not_trust|tostring')" "true" "no isp ip trust"
assert_eq "$(am_map_get '.policy.never_auto_full_profile|tostring')" "true" "never auto full profile"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED"
  exit 1
fi
echo "ALL_UNIT_OK"
