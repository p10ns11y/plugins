#!/usr/bin/env bash
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
need=(
  plugin.json
  README.md
  LICENSE
  commands/ai-flow-audit.md
  skills/ai-flow-audit/SKILL.md
  skills/ai-flow-audit/references/waste-ledger.md
  skills/ai-flow-audit/references/myth-card.md
  skills/ai-flow-audit/references/irreversible-checklist.md
  skills/ai-flow-audit/references/interview-guide.md
  examples/paper-lantern-worked-example.md
)
for f in "${need[@]}"; do
  test -f "$ROOT/$f" || { echo "missing $f"; exit 1; }
done
grep -q 'ai-flow-audit' "$ROOT/plugin.json"
grep -q 'Paper Lantern Labs' "$ROOT/examples/paper-lantern-worked-example.md"
grep -q 'fictional' "$ROOT/examples/paper-lantern-worked-example.md"
grep -q 'waste-ledger' "$ROOT/skills/ai-flow-audit/SKILL.md"
grep -q 'irreversible-checklist' "$ROOT/skills/ai-flow-audit/SKILL.md"
# Avoid banned word in agent-facing text
if grep -riw 'gate' "$ROOT/skills" "$ROOT/commands" "$ROOT/examples" 2>/dev/null; then
  echo "FAIL: word 'gate' found in agent-facing paths"
  exit 1
fi
echo "ok ai-flow-audit thin"
