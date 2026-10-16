#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"

missing=0
require() {
  local label="$1" path="$2"
  if [[ ! -x "$path" ]]; then
    echo "missing $label" >&2
    missing=1
  fi
}

require "tstack/scripts/tstack-state" "$ROOT/scripts/tstack-state"
require "tstack/bin/capture-sweep" "$ROOT/bin/capture-sweep"
require "tstack/bin/merge-check" "$ROOT/bin/merge-check"
require "tstack/bin/premflow-path" "$ROOT/bin/premflow-path"
require "tstack/bin/public-row" "$ROOT/bin/public-row"
require "concordance/bin/concordance" "$REPO/concordance/bin/concordance"
require "control-plane/bin/feed" "$REPO/control-plane/bin/feed"
require "intelli-route/bin/route" "$REPO/intelli-route/bin/route"
require "mission-map/rust/target/debug/mission-map-graph" "$REPO/mission-map/rust/target/debug/mission-map-graph"
[[ "$missing" -eq 0 ]] || exit 1

export PATH="$REPO/mission-map/rust/target/debug:$PATH"
exec python3 "$ROOT/test/e2e/run_flows.py"
