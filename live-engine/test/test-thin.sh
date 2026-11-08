#!/usr/bin/env bash
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
need=(
  plugin.json
  README.md
  LICENSE
  commands/live-engine.md
  skills/live-engine/SKILL.md
)
for f in "${need[@]}"; do
  test -f "$ROOT/$f" || { echo "missing $f"; exit 1; }
done
grep -q '"name": "live-engine"' "$ROOT/plugin.json"
grep -q 'one live working set' "$ROOT/skills/live-engine/SKILL.md"
grep -q 'name: Live engine' "$ROOT/skills/live-engine/SKILL.md"
echo "ok live-engine thin"
