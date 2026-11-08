#!/usr/bin/env bash
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
need=(
  plugin.json
  README.md
  LICENSE
  commands/live-context.md
  skills/live-context/SKILL.md
)
for f in "${need[@]}"; do
  test -f "$ROOT/$f" || { echo "missing $f"; exit 1; }
done
grep -q '"name": "live-context"' "$ROOT/plugin.json"
grep -q 'one live context' "$ROOT/skills/live-context/SKILL.md"
grep -q 'name: Live context' "$ROOT/skills/live-context/SKILL.md"
echo "ok live-context thin"
