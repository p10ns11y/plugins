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
import json, sys
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
    ("Own your knives", "readme own knives"),
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

scaled = (root / "skills/scaled-verifiers/SKILL.md").read_text()
if "50:30" in scaled and "Our adaptation" in scaled:
    ok("scaled-verifiers sampling time")
else:
    bad("scaled-verifiers sampling time")
if "57:30" in scaled:
    ok("scaled one-way verifiability")
else:
    bad("scaled one-way verifiability")

events = (root / "skills/events-over-timers/SKILL.md").read_text()
if "37:30" in events and "44:30" in events:
    ok("events subscription and coordinator times")
else:
    bad("events times")
if "48:30" in events and "code-scanning" in events:
    ok("events 48:30 is scanning not buffer")
else:
    bad("events 48:30 clarification")
if "laptop-1" in events or "mac-mini" in events:
    bad("events alias host names")
else:
    ok("events no alias hosts")

findings = (root / "skills/findings-first/SKILL.md").read_text()
if "Our additions" in findings and "3 Oct" not in findings:
    ok("findings ours labeled, no 3 Oct")
else:
    bad("findings labeling")

scripts = (root / "skills/shared-scripts/SKILL.md").read_text()
if "Our additions" in scripts and "posting" in scripts.lower():
    ok("shared-scripts inline example")
else:
    bad("shared-scripts example")

kitchen = (root / "skills/kitchen-time/SKILL.md").read_text()
import re
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
