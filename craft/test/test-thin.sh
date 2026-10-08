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
        "bin/crap-score.mjs", "bin/mutation-score.mjs", "bin/js-score-lib.mjs", "bin/crap-score-cc.mjs",
        "bin/rust-crap/Cargo.toml", "bin/rust-crap/Cargo.lock", "bin/rust-crap/src/main.rs",
        "test/check-scores.sh", "test/check-js-scores.sh", "test/js-score.test.mjs", "test/native-crap.test.mjs",
        "test/check-acceptance-first.sh", "test/check-proof.sh")
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
check("Alberto Savoia" in notice and "below 4" in thresholds and "zcLPGC-tvgk" in notice, "attribution")
speaker = "after Robert C. Martin's ongoing multi-agent experiment"
check(speaker in read(root / "plugin.json") and speaker in read(repo / ".grok-plugin/marketplace.json"), "speaker named")
check("Robert C. Martin" in readme and "zcLPGC-tvgk" in readme, "plugin readme names the talk")
time_re = re.compile(r"\b\d:\d\d:\d\d\b")
def talk_lines(text):
    hide, found = False, []
    for num, line in enumerate(text.splitlines(), 1):
        if line.strip().startswith("```"):
            hide = not hide
        elif not hide and (time_re.search(line) or any(len(part.split()) >= 4 for part in re.findall(r'"([^"\n]*)"', line))):
            found.append(num)
    return found
flagged = [f"{path.relative_to(root)}:{num}" for path in sorted(root.rglob("*.md")) if path.name != "NOTICE.md" for num in talk_lines(read(path))]
texts = [json.loads(read(root / "plugin.json"))["description"]]
texts += [item["description"] for item in json.loads(read(repo / ".grok-plugin/marketplace.json"))["plugins"] if item["name"] == "craft"]
flagged += ["json description"] if any('"' in text or time_re.search(text) for text in texts) else []
flagged += [f"README.md:{num}" for num, line in enumerate(read(repo / "README.md").splitlines(), 1) if "**craft**" in line and talk_lines(line)]
check(not flagged, "talk quotes stay in NOTICE" if not flagged else "talk outside NOTICE " + " ".join(flagged))
agent = [root / "skills/craft/SKILL.md"]
agent += sorted((root / "skills/craft/references").glob("*.md"))
agent += sorted((root / "agents").glob("*.md"))
agent += sorted((root / "commands").glob("*.md"))
agent_re = re.compile(r"robert\s+c\.?\s+martin|\bmartin\b|uncle\s+bob|matt\s+pocock|house\s+rule|\bnot\s+his\b|\bhe\b|\bhis\b|savoia|bob\s+evans|crap4j|fundamentals\s+in\s+the\s+age\s+of\s+ai|zcLPGC-tvgk|youtu\.?be|\b\d:\d\d:\d\d\b|\b\d{1,2}\s+aug(ust)?\s+20\d\d\b", re.I)
agent_bad = [f"{path.relative_to(root)}:{num}" for path in agent for num, line in enumerate(read(path).splitlines(), 1) if agent_re.search(line)]
check(not agent_bad, "agent text stays actionable" if not agent_bad else "agent text " + " ".join(agent_bad))
scout = "Boy-scout cleanup stays inside the touched files."
check(scout in skill and scout in command and "house rule" in readme, "scout rule")
check("A .feature file, or a file under features/ or qa/, exists before the first production commit" in readme, "specifier check")
check("crap_max" in skill and "crap_max" not in command and "--diff" not in readme, "one card")
check("Bend covers pure transitions only, not IO or timing." in readme and "2.0.35" in readme and "v4.34.0" in readme and "check-proof.sh" in readme, "bend pin")
check("LAWS.bend" in read(root / "skills/craft/references/acceptance.md") and "Do not weaken the law." in skill and "non-Bend code" in skill, "laws")
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
lines = sum(p.read_bytes().count(b"\n") for p in root.rglob("*") if p.is_file() and "__pycache__" not in p.parts and "target" not in p.parts)
check(lines <= 2810, f"plugin lines {lines}")
print("---")
print(f"{len(bad)} failure(s)" if bad else "ALL CHECKS PASSED")
sys.exit(1 if bad else 0)
PY
bash "$(dirname "$0")/check-js-scores.sh"
