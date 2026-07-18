#!/usr/bin/env bash
# Honest --yes expand: real side effects without dry-run, using local fixture repo.
# Proves consent-gated expand is not a no-op.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GROK_PLUGIN_ROOT="$ROOT"
FIX="$ROOT/fixtures/mock-arch"
export ARCH_MACHINE_ROOT="$FIX"
EXPAND="$ROOT/bin/am-expand"
chmod +x "$EXPAND" "$ROOT/bin/"* "$FIX/install.sh" "$FIX/modules/security/install.sh"

# Clean prior expand artifacts
rm -rf "$FIX/.arch-expand-state" \
  "$FIX/modules/security/.agent-expanded" \
  "$FIX/modules/security/expanded-out" \
  "$FIX/modules/productivity/.agent-expanded"

echo "=== 1: --yes module expand (security fixture, NO dry-run) ==="
out=$("$EXPAND" security --yes --no-pull 2>&1)
ec=$?
echo "$out"
[[ "$ec" -eq 0 ]] || { echo "expected exit 0, got $ec"; exit 1; }
echo "$out" | grep -q 'module_expand_ok: security' || { echo "missing module_expand_ok"; exit 1; }
echo "$out" | grep -vq 'dry-run' || { echo "unexpected dry-run in real path"; exit 1; }

# Side effects must exist on disk
[[ -f "$FIX/modules/security/expanded-out/result.txt" ]] || {
  echo "missing real work product: expanded-out/result.txt"
  exit 1
}
[[ -f "$FIX/modules/security/.agent-expanded" ]] || {
  echo "missing .agent-expanded marker"
  exit 1
}
[[ -f "$FIX/.arch-expand-state/security.stamp" ]] || {
  echo "missing plugin stamp"
  exit 1
}
echo "ok real side effects on disk"

echo "=== 2: fail closed still holds ==="
set +e
"$EXPAND" security 2>/dev/null
ec=$?
set -e
[[ "$ec" -eq 2 ]] || { echo "expected exit 2 without --yes"; exit 1; }
echo "ok fail closed"

echo "=== 3: module without --agent-expand hook still stamps (productivity) ==="
outp=$("$EXPAND" productivity --yes --no-pull 2>&1)
echo "$outp"
echo "$outp" | grep -q 'module_expand_ok: productivity'
[[ -f "$FIX/.arch-expand-state/productivity.stamp" ]]
[[ -f "$FIX/modules/productivity/.agent-expanded" ]]
echo "ok stamp+marker path for hookless module"

# Cleanup fixture artifacts so git stays clean
rm -rf "$FIX/.arch-expand-state" \
  "$FIX/modules/security/.agent-expanded" \
  "$FIX/modules/security/expanded-out" \
  "$FIX/modules/productivity/.agent-expanded"

echo "EXPAND_REAL_OK"
