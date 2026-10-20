#!/usr/bin/env bash
# Put tstack-state and pr-triage on PATH and create the state file.
# Usage: scripts/install.sh [BIN_DIR]   (default ~/.local/bin)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${1:-$HOME/.local/bin}"
mkdir -p "$BIN"
ln -sfn "$ROOT/scripts/tstack-state" "$BIN/tstack-state"
ln -sfn "$ROOT/bin/pr-triage" "$BIN/tstack-pr-triage"
"$BIN/tstack-state" init
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "add $BIN to PATH" >&2 ;;
esac
