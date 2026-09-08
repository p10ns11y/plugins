#!/usr/bin/env bash
# Thin structure check — no runtime math required.
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
need=(
  plugin.json
  README.md
  commands/uncertainty-laws.md
  skills/uncertainty-laws/SKILL.md
  skills/uncertainty-laws/references/four-laws.md
  skills/uncertainty-laws/references/scenarios.md
  skills/uncertainty-laws/references/mission-map-link.md
  examples/wealth-fog.md
  NOTICE.md
)
for f in "${need[@]}"; do
  test -f "$ROOT/$f" || { echo "missing $f"; exit 1; }
done
grep -q 'uncertainty-laws' "$ROOT/plugin.json"
grep -q '0xVenix/status/2095614241969520904' "$ROOT/NOTICE.md"
grep -q 'mission-map' "$ROOT/skills/uncertainty-laws/references/mission-map-link.md"
echo "ok uncertainty-laws thin"
