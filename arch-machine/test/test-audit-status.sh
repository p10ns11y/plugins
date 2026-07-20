#!/usr/bin/env bash
# Probe am-status / am-audit / am-archy against real or missing repo (honest).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GROK_PLUGIN_ROOT="$ROOT"

fail=0

echo "== am-status =="
if ! "$ROOT/bin/am-status"; then
  # exit 1 ok if no repo — still must print plugin path
  echo "(am-status non-zero without full core — checking headers)"
fi
out="$("$ROOT/bin/am-status" 2>&1 || true)"
echo "$out" | grep -q 'plugin:' || { echo "FAIL: no plugin line"; fail=1; }
echo "$out" | grep -qE 'archy:|tinfoil:' || { echo "FAIL: no archy/tinfoil probe"; fail=1; }

echo "== am-archy --print-root (if repo) =="
if root="$("$ROOT/bin/am-archy" --print-root 2>/dev/null)"; then
  echo "root=$root"
  [[ -f "$root/install.sh" ]] || { echo "FAIL: install.sh missing at root"; fail=1; }
  if [[ -f "$root/maintenance/security-audit.sh" ]]; then
    echo "== am-audit --dry-run =="
    dry="$("$ROOT/bin/am-audit" --dry-run 2>&1 || true)"
    echo "$dry" | head -20
    echo "$dry" | grep -q '## SUMMARY' || { echo "FAIL: dry audit missing SUMMARY"; fail=1; }
    echo "$dry" | grep -q 'malware=' || { echo "FAIL: dry audit missing malware="; fail=1; }
    echo "$dry" | grep -qv '🚀' || true
  fi
else
  echo "no repo resolved — skip audit dry-run (ok for clean CI)"
fi

echo "== core-map surfaces =="
jq -e '.surfaces.primary == "archy"' "$ROOT/core-map.json" >/dev/null
jq -e '.policy.prefer_archy_over_gum_tui == true' "$ROOT/core-map.json" >/dev/null
jq -e '.core.repo_paths | index("crates/archy/")' "$ROOT/core-map.json" >/dev/null

if [[ "$fail" -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "OK"
