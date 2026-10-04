#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  [[ -f "$ROOT/$1" || -d "$ROOT/$1" ]] && ok "exists $1" || bad "missing $1"
}

for habit in shared-scripts findings-first events-over-timers workflow-skills repeat-or-leave scaled-verifiers kitchen-time; do
  need "skills/$habit/SKILL.md"
done

need plugin.json
need LICENSE
need NOTICE.md
need README.md
need agents/michelin-kitchen.md
need commands/michelin-kitchen.md
need evals/evals.json

if [[ -f "$ROOT/commands/shared-scripts.md" ]]; then bad "stale per-habit command"; else ok "single command file"; fi
if [[ -d "$ROOT/examples" ]]; then bad "examples dir present"; else ok "no examples dir"; fi
if [[ -f "$ROOT/skills/michelin-kitchen/SKILL.md" ]]; then bad "index skill still present"; else ok "index folded into agent"; fi

python3 - "$ROOT" <<'PY'
import json, re, sys
from pathlib import Path

root = Path(sys.argv[1])
fail = 0

def ok(msg):
    print(f"ok  {msg}")

def bad(msg):
    global fail
    print(f"FAIL {msg}")
    fail += 1

pj = json.loads((root / "plugin.json").read_text())
if pj.get("name") == "michelin-kitchen":
    ok("plugin.json name")
else:
    bad("plugin.json name")
repo = root.parent
market = json.loads((repo / ".grok-plugin/marketplace.json").read_text())
mk = next(item["description"] for item in market["plugins"] if item["name"] == "michelin-kitchen")
if "Lauren Tan" in pj["description"] and "Matt Pocock" in pj["description"]:
    ok("plugin.json credits the talk")
else:
    bad("plugin.json credits the talk")
if "Lauren Tan" in mk and "Matt Pocock" in mk:
    ok("marketplace credits the talk")
else:
    bad("marketplace credits the talk")

ev = json.loads((root / "evals/evals.json").read_text())
skills = {p.name for p in (root / "skills").iterdir() if p.is_dir()}
seen = set()
for case in ev.get("evals", []):
    cid = case.get("id", "?")
    exp = case.get("expected_skill")
    if exp is None:
        ok(f"eval {cid} null skill")
        continue
    seen.add(exp)
    if exp in skills:
        ok(f"eval {cid} -> {exp}")
    else:
        bad(f"eval {cid} missing skill folder {exp}")

required = {
    "shared-scripts", "findings-first", "events-over-timers",
    "workflow-skills", "repeat-or-leave", "scaled-verifiers", "kitchen-time",
}
missing_cases = required - seen
for skill in sorted(missing_cases):
    bad(f"no eval case for {skill}")

readme = (root / "README.md").read_text()
checks = [
    ("Lauren Tan", "readme credits Lauren Tan"),
    ("Matt Pocock", "readme credits Matt Pocock"),
    ("Our adaptation", "readme marks adaptations"),
    ("youtube.com/watch?v=MN9dGgmLyso", "readme youtube link"),
    ("I don't want to sell this", "readme pstack caveat verbatim"),
    ("everyone should have their own set of knives", "readme knives quote"),
]
for needle, label in checks:
    if needle in readme:
        ok(label)
    else:
        bad(label)
if "3 Oct" in readme:
    bad("readme still has 3 Oct story")
else:
    ok("readme no 3 Oct story")
if "host-neutral" in readme.lower():
    bad("readme host-neutral")
else:
    ok("readme no host-neutral")
if "gate" in readme.lower():
    bad("readme uses gate")
else:
    ok("readme avoids gate")

notice = (root / "NOTICE.md").read_text()
if "youtube.com/watch?v=MN9dGgmLyso" in notice:
    ok("notice youtube link")
else:
    bad("notice youtube link")
if "trust-stack" in notice:
    bad("notice overlap table leaked")
else:
    ok("notice no overlap table")

for needle, label in (
    ("~23:30", "notice shared-scripts time"),
    ("no LLM in the checker are ours", "notice shared-scripts ours"),
    ("before pinging anyone", "notice findings before ping"),
    ("pointer-only notification", "notice findings pointer"),
    ("I have some routines like that as well", "notice events quote"),
    ("code-scanning routine", "notice events scanning"),
    ("36:30", "notice events subscription"),
    ("43:30", "notice events coordinator"),
    ("almost like implementation details", "notice workflow quote"),
    ("really focus on the workflow", "notice workflow focus"),
    ("maybe there's nothing to fix there", "notice repeat quote"),
    ("instead of like 10 verifier agents", "notice scaled quote"),
    ("49:30", "notice scaled sampling"),
    ("56:30", "notice scaled verifiability"),
    ("risk ladder is ours", "notice scaled ladder"),
    ("no garlic press", "notice kitchen knives"),
    ("No calendar slice was prescribed", "notice kitchen slice"),
    ("poteto", "notice names poteto"),
):
    if needle in notice:
        ok(label)
    else:
        bad(label)

read = lambda path: path.read_text(errors="ignore")
def check(cond, msg):
    (ok if cond else bad)(msg)
agent = sorted((root / "skills").glob("*/SKILL.md"))
agent += sorted((root / "skills").glob("*/references/*.md"))
agent += sorted((root / "agents").glob("*.md"))
agent += sorted((root / "commands").glob("*.md"))
agent_re = re.compile(r"robert\s+c\.?\s+martin|\bmartin\b|uncle\s+bob|matt\s+pocock|house\s+rule|\bnot\s+his\b|\bhe\b|\bhis\b|savoia|bob\s+evans|crap4j|fundamentals\s+in\s+the\s+age\s+of\s+ai|zcLPGC-tvgk|youtu\.?be|\b\d:\d\d:\d\d\b|\b\d{1,2}\s+aug(ust)?\s+20\d\d\b|lauren\s+tan|\bpoteto\b|mn9dggmlyso|~\d+:\d\d|our\s+additions|our\s+adaptation", re.I)
agent_bad = [f"{path.relative_to(root)}:{num}" for path in agent for num, line in enumerate(read(path).splitlines(), 1) if agent_re.search(line)]
check(not agent_bad, "agent text stays actionable" if not agent_bad else "agent text " + " ".join(agent_bad))

events = read(root / "skills/events-over-timers/SKILL.md")
if "code-scanning" in events:
    ok("events scanning stays actionable")
else:
    bad("events scanning stays actionable")
if "laptop-1" in events or "mac-mini" in events:
    bad("events alias host names")
else:
    ok("events no alias hosts")

findings = read(root / "skills/findings-first/SKILL.md")
if "3 Oct" not in findings:
    ok("findings no 3 Oct")
else:
    bad("findings no 3 Oct")

scripts = read(root / "skills/shared-scripts/SKILL.md")
if "posting" in scripts.lower():
    ok("shared-scripts inline example")
else:
    bad("shared-scripts example")

kitchen = read(root / "skills/kitchen-time/SKILL.md")
if re.search(r"\d+\s*%|\d+\s*hours|\d+\s*h\/week|hours.per.week", kitchen, re.I):
    bad("kitchen-time invents time slice")
else:
    ok("kitchen-time no invented slice")

repeat = (root / "skills/repeat-or-leave/SKILL.md").read_text()
if "trust-stack" in repeat and "shape | check" not in repeat:
    ok("repeat links trust-stack")
else:
    bad("repeat copies trust-stack table")

sys.exit(fail)
PY
rc=$?
if [[ "$rc" -ne 0 ]]; then fail=$((fail + rc)); fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
