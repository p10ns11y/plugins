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
python_rc=0
python3 - "$ROOT" <<'PY' || python_rc=$?
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
fail = 0

def ok(msg):
    print(f"ok  {msg}")

def bad(msg):
    global fail
    print(f"FAIL {msg}")
    fail += 1

def check(cond, msg):
    (ok if cond else bad)(msg)

read = lambda path: path.read_text(errors="ignore")
notice = read(root / "NOTICE.md")
check(
    "Venix" in notice
    and "0xVenix" in notice
    and "2095614241969520904" in notice
    and "The Four Laws of Probability That Quietly Decide Who Keeps the Money" in notice,
    "notice carries the credit",
)
agent = sorted((root / "skills").glob("*/SKILL.md"))
agent += sorted((root / "skills").glob("*/references/*.md"))
agent += sorted((root / "agents").glob("*.md"))
agent += sorted((root / "commands").glob("*.md"))
cursor_commands = root / "cursor" / "commands"
if cursor_commands.is_dir():
    agent += sorted(cursor_commands.glob("*.md"))
agent_re = re.compile(r"robert\s+c\.?\s+martin|\bmartin\b|uncle\s+bob|matt\s+pocock|house\s+rule|\bnot\s+his\b|\bhe\b|\bhis\b|savoia|bob\s+evans|crap4j|fundamentals\s+in\s+the\s+age\s+of\s+ai|zcLPGC-tvgk|youtu\.?be|\b\d:\d\d:\d\d\b|\b\d{1,2}\s+aug(ust)?\s+20\d\d\b|lauren\s+tan|\bpoteto\b|mn9dggmlyso|~\d+:\d\d|our\s+additions|our\s+adaptation", re.I)
agent_bad = [f"{path.relative_to(root)}:{num}" for path in agent for num, line in enumerate(read(path).splitlines(), 1) if agent_re.search(line)]
check(not agent_bad, "agent text stays actionable" if not agent_bad else "agent text " + " ".join(agent_bad))
blob = "\n".join(read(path) for path in agent)
check("0xVenix" not in blob and "2095614241969520904" not in blob, "agent text omits the credit")

restored = (
    ("uncertainty-laws", "https://x.com/0xVenix/status/2095614241969520904"),
)
repo = root.parent
for plugin_name, url in restored:
    plugin = repo / plugin_name
    placed = [name for name in ("NOTICE.md", "README.md") if (plugin / name).is_file() and url in read(plugin / name)]
    check(bool(placed), f"restored link in notice or readme: {url}" if placed else f"restored link missing from notice and readme: {url}")
    faces = []
    faces += sorted(plugin.glob("**/SKILL.md"))
    faces += sorted(plugin.glob("**/references/*.md"))
    faces += sorted(plugin.glob("**/agents/*.md"))
    faces += sorted(plugin.glob("**/commands/*.md"))
    faces += sorted(path for path in plugin.rglob("*") if path.is_file() and ("flow" in path.name.lower() or "/.grok/workflows/" in path.as_posix()))
    seen = set()
    hits = []
    for path in faces:
        if not path.is_file():
            continue
        key = path.resolve()
        if key in seen:
            continue
        seen.add(key)
        if url in read(path):
            hits.append(str(path.relative_to(plugin)))
    check(not hits, "restored link stays out of agent files" if not hits else "restored link in agent files " + " ".join(hits))
sys.exit(fail)
PY
if [[ "$python_rc" -ne 0 ]]; then
  exit "$python_rc"
fi
echo "ok uncertainty-laws thin"
