#!/usr/bin/env bash
# Trust layers. No merge bot, no vendored pstack.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  [[ -f "$ROOT/$1" ]] && ok "exists $1" || bad "missing $1"
}

need plugin.json
need LICENSE
need NOTICE.md
need README.md
need commands/trust-stack.md
need agents/trust-stack.md
need skills/trust-stack/SKILL.md
need skills/trust-stack/references/layers.md
need skills/trust-stack/references/day-0.md
need bend/trust.bend
need bend/LAWS.bend
need bend/PROOF.bend
need test/bend-critical.sh

if [[ -d "$ROOT/poteto-mode" || -d "$ROOT/playbooks" ]]; then
  bad "pstack vendored"
else
  ok "no pstack copy"
fi

skill="$(cat "$ROOT/skills/trust-stack/SKILL.md")"
for id in shape check watch skill guide; do
  echo "$skill" | grep -q "\`$id\`" && ok "layer $id" || bad "missing layer $id"
done
echo "$skill" | grep -q 'This plugin does not merge' && ok "does not merge" || bad "merge guard missing"
echo "$skill" | grep -q 'codebase is the memory' && ok "memory axiom" || bad "memory axiom missing"
echo "$skill" | grep -q 'One owner' && ok "one owner" || bad "owner rule missing"

if echo "$skill" | grep -qi 'agents merge'; then
  bad "skill tells agents to merge"
else
  ok "skill does not instruct a merge"
fi

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q '2102050467505430555' && ok "notices the talk" || bad "missing talk"
echo "$notice" | grep -q 'bend-lang.com' && ok "notices Bend" || bad "missing Bend"
echo "$notice" | grep -q 'does not merge' && ok "notice refuses merge" || bad "notice missing merge refusal"
echo "$notice" | grep -q 'Lauren Tan' && ok "credits Lauren Tan" || bad "missing credit"
echo "$skill" | grep -q 'bend-critical.sh' && ok "shape layer names the Bend proof" || bad "missing Bend proof"
echo "$skill" | grep -q 'that proof was not run' && ok "absent bend is not a pass" || bad "absent bend treated as a pass"
echo "$skill" | grep -q 'references/day-0.md' && ok "day-0 card is named" || bad "day-0 card is not named"

day0="$(cat "$ROOT/skills/trust-stack/references/day-0.md")"
echo "$day0" | grep -q "user's latest message" && ok "day-0 side effect" || bad "day-0 side effect missing"
echo "$day0" | grep -q "admitted pulse file" && ok "day-0 story page" || bad "day-0 story page missing"
echo "$day0" | grep -q "Auto-merge stops" && ok "day-0 auto-merge stop" || bad "day-0 auto-merge stop missing"

if bash "$ROOT/test/bend-critical.sh" | tee /dev/stderr | grep -q -e 'All terms check.' -e 'bend not installed'; then
  ok "Bend proof of the trust laws"
else
  bad "Bend proof of the trust laws"
fi

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
    "Lauren Tan" in notice
    and "poteto-mode" in notice
    and "2102050467505430555" in notice
    and "production setup" in notice,
    "notice carries the credit",
)
agent = sorted((root / "skills").glob("*/SKILL.md"))
agent += sorted((root / "skills").glob("*/references/*.md"))
agent += sorted((root / "agents").glob("*.md"))
agent += sorted((root / "commands").glob("*.md"))
cursor_commands = root / "cursor" / "commands"
if cursor_commands.is_dir():
    agent += sorted(cursor_commands.glob("*.md"))
agent_re = re.compile(r"robert\s+c\.?\s+martin|\bmartin\b|uncle\s+bob|matt\s+pocock|house\s+rule|\bnot\s+his\b|\bhe\b|\bhis\b|savoia|bob\s+evans|crap4j|fundamentals\s+in\s+the\s+age\s+of\s+ai|zcLPGC-tvgk|youtu\.?be|\b\d:\d\d:\d\d\b|\b\d{1,2}\s+aug(ust)?\s+20\d\d\b|lauren\s+tan|\bpoteto\b(?!-mode)|mn9dggmlyso|~\d+:\d\d|our\s+additions|our\s+adaptation", re.I)
agent_bad = [f"{path.relative_to(root)}:{num}" for path in agent for num, line in enumerate(read(path).splitlines(), 1) if agent_re.search(line)]
check(not agent_bad, "agent text stays actionable" if not agent_bad else "agent text " + " ".join(agent_bad))
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
