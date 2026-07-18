#!/usr/bin/env bash
# Fixture module with real --agent-expand side effects (no network/sudo).
set -euo pipefail
MOD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  --agent-expand)
    echo "fixture agent-expand: security"
    # Real side effect: create work product under module tree
    mkdir -p "$MOD/expanded-out"
    echo "expanded-at=$(date -Iseconds)" >"$MOD/expanded-out/result.txt"
    date -Iseconds >"$MOD/.agent-expanded"
    echo "wrote $MOD/expanded-out/result.txt"
    echo "agent_expand_ok: security"
    exit 0
    ;;
  *)
    echo "Usage: $0 --agent-expand" >&2
    exit 2
    ;;
esac
