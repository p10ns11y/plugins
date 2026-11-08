#!/usr/bin/env bash
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
need=(
  plugin.json
  README.md
  LICENSE
  commands/cos.md
  skills/cos/SKILL.md
)
for f in "${need[@]}"; do
  test -f "$ROOT/$f" || { echo "missing $f"; exit 1; }
done
grep -q '"name": "cos"' "$ROOT/plugin.json"
grep -q 'one live context' "$ROOT/skills/cos/SKILL.md"
echo "ok cos thin"
