#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" << 'PY'
import json, re, sys
from pathlib import Path
root, bad = Path(sys.argv[1]), []
repo = root.parent
def check(cond, msg):
    print(("ok  " if cond else "FAIL ") + msg)
    if not cond:
        bad.append(msg)
need = ("plugin.json", "LICENSE", "NOTICE.md", "README.md", "commands/craft.md", "agents/craft.md",
        "skills/craft/SKILL.md", "skills/craft/references/thresholds.md", "skills/craft/references/acceptance.md",
        "skills/craft/evals/evals.json", "bin/crap-score.py", "bin/mutation-score.py", "bin/score_lib.py",
        "test/check-scores.sh", "test/check-acceptance-first.sh")
for rel in need:
    check((root / rel).is_file(), f"exists {rel}")
check(not (root / "skills/craft/references/chain.md").exists(), "chain merged")
read = lambda path: path.read_text(errors="ignore")
blob = "\n".join(read(p) for p in root.rglob("*") if p.is_file() and p.name != "test-thin.sh")
check("inspired" not in blob.lower() and "predates" not in blob.lower(), "no extra origin claim")
notice = read(root / "NOTICE.md")
skill = read(root / "skills/craft/SKILL.md")
command = read(root / "commands/craft.md")
readme = read(root / "README.md")
thresholds = read(root / "skills/craft/references/thresholds.md")
check("Video times (h:mm:ss):" in notice and "0:21:57" in notice and "0.95" in thresholds, "time label")
check("Alberto Savoia" in notice and "below four" in thresholds and "zcLPGC-tvgk" in notice, "attribution")
speaker = "after Robert C. Martin's ongoing multi-agent experiment"
pages = [root / rel for rel in ("plugin.json", "commands/craft.md", "agents/craft.md", "skills/craft/SKILL.md")]
pages += [repo / "README.md", repo / ".grok-plugin/marketplace.json"]
check(all(speaker in read(page) for page in pages), "speaker named")
forbidden = (
    "in the midst of trying to get multiple agents " "talking to each other and handing off to each other",
    "run crap analysis " "and just general code review",
)
kept = (
    "going to have " "100% coverage",
    "sacrificing productivity for higher quality and at some point that's got to give way. But I haven't found the " "end point of that yet",
)
outside = "\n".join(
    read(p) for p in root.rglob("*")
    if p.is_file() and p.name != "NOTICE.md" and "__pycache__" not in p.parts
)
check(all(q not in outside for q in forbidden) and all(q in notice and q not in outside for q in kept), "talk quotes stay in NOTICE")
rule = "Boy-scout cleanup stays inside the touched files. That limit is our house rule, not his."
check(rule in skill and rule in command and "house rule" in readme, "scout rule")
check("A .feature file, or a file under features/ or qa/, exists before the first production commit" in readme, "specifier check")
check("crap_max" in skill and "crap_max" not in command and "--diff" not in readme, "one card")
check(all(name not in readme and name not in notice for name in ("split-machine", "trust-stack", "pstack-map")), "neighbors stay in the skill")
evals = json.loads(read(root / "skills/craft/evals/evals.json"))
skills = {"craft": root / "skills/craft/SKILL.md", "split-machine": repo / "split-machine/skills/split-machine/SKILL.md"}
for case in evals["evals"]:
    check("assertions" not in case and "expected_script" not in case, f"{case['id']} is a fact")
    check(case["expected_skill"] in skills and skills[case["expected_skill"]].is_file(), f"skill {case['expected_skill']}")
    check(all(("exit" in item) or ("fact" in item) for item in case["pass"]), f"{case['id']} pass fact")
check({c["id"] for c in evals["evals"]} == {"craft-acceptance-before-coder", "craft-crap-cleaner", "craft-mutation-hardener", "craft-neg-router"}, "eval ids")
joined = json.dumps(evals)
for needle in ("check-acceptance-first.sh", "--functions uncovered", "--max 6", "bad-split-cov", "--min 0.95", "bad-mutants", "lib.py is unchanged", "neither crap-score.py nor mutation-score.py was run"):
    check(needle in joined, f"eval has {needle}")
wf = read(repo / ".github/workflows/plugins.yml")
check("permissions:" in wf and "contents: read" in wf and "pull_request_target" not in wf, "workflow permissions")
check(wf.count("GH_TOKEN") == 1 and "intelli-route" in wf[max(0, wf.index("GH_TOKEN") - 400):wf.index("GH_TOKEN") + 80], "GH_TOKEN only on intelli-route")
uses = re.findall(r"uses:\s*(\S+)", wf)
check(uses and all(re.fullmatch(r"[\w.-]+/[\w.-]+@[0-9a-f]{40}", item) for item in uses), "actions pinned")
lines = sum(p.read_bytes().count(b"\n") for p in root.rglob("*") if p.is_file() and "__pycache__" not in p.parts)
check(lines <= 892, f"plugin lines {lines}")
print("---")
print(f"{len(bad)} failure(s)" if bad else "ALL CHECKS PASSED")
sys.exit(1 if bad else 0)
PY
