#!/usr/bin/env bash
# Thin plugin: pulse-memory owns skill + optional rhai. No tether, no always-on hooks.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  local p="$1"
  [[ -f "$ROOT/$p" || -d "$ROOT/$p" ]] && ok "exists $p" || bad "missing $p"
}

need plugin.json
need commands/pulse-memory.md
need cursor/commands/pulse-memory.md
need agents/pulse-memory.md
need skills/pulse-memory/SKILL.md
need skills/pulse-memory/references/admissions.md
need skills/pulse-memory/references/store.md
need skills/pulse-memory/references/usecases.md
need .grok/workflows/pulse-memory.rhai
need test/fixtures/thinking.md
need test/fixtures/harness.md

if [[ -d "$ROOT/c" ]]; then bad "c/ present — EVA owns tether"; else ok "no c/"; fi
if [[ -d "$ROOT/hooks" ]] || [[ -f "$ROOT/hooks.json" ]]; then bad "hooks — Winds"; else ok "no hooks"; fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "pulse-memory"' && ok "plugin.json name" || bad "plugin.json name"

sk="$(cat "$ROOT/skills/pulse-memory/SKILL.md")"
echo "$sk" | grep -q '^name: pulse-memory' && ok "skill name" || bad "skill name"
echo "$sk" | grep -qi 'hint tags\|status:' && ok "skill tags" || bad "skill missing tags"
echo "$sk" | grep -qi 'not in the evidence' && ok "skill abstention" || bad "skill missing abstention"
echo "$sk" | grep -qi 'do not.*average\|Never average' && ok "skill no-average" || bad "skill averages"

rh="$(cat "$ROOT/.grok/workflows/pulse-memory.rhai")"
echo "$rh" | grep -q 'name: "pulse-memory"' && ok "rhai meta.name" || bad "rhai meta.name"
echo "$rh" | grep -q 'as_of' && ok "rhai requires as_of" || bad "rhai missing as_of"
echo "$rh" | grep -q 'mode' && ok "rhai mode" || bad "rhai missing mode"
uc="$(cat "$ROOT/skills/pulse-memory/references/usecases.md")"
echo "$uc" | grep -q 'thinking_path' && ok "usecases thinking_path" || bad "usecases missing thinking_path"
echo "$uc" | grep -q 'harness_path' && ok "usecases harness_path" || bad "usecases missing harness_path"
echo "$uc" | grep -q 'as_of' && ok "usecases as_of" || bad "usecases missing as_of"

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
readme = read(root / "README.md")
reference_lines = (
    "- [Pulse instead of dump](https://captain.kingsparrow.space/focus/memory-issue), credits the canonical prose for a compact pulse instead of a context dump.",
    "- [Archive is not memory](https://captain.kingsparrow.space/focus/memory-issue/archive-not-memory), credits the canonical prose for the admissions rule that archive residue is not memory.",
)
parts = readme.split("## References", 1)
check(len(parts) == 2 and "Essays (canonical prose)" in parts[0], "readme References heading")
missing = [line for line in reference_lines if line not in parts[1].splitlines()]
check(not missing, "readme reference lines" if not missing else "readme reference lines missing")
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
check("kingsparrow" not in blob.lower(), "agent text omits the essay credit")
sys.exit(fail)
PY
if [[ "$python_rc" -ne 0 ]]; then fail=$((fail + python_rc)); fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
