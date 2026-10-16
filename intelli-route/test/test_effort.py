#!/usr/bin/env python3
"""Table-driven effort decisions from intelli-route/bin/route."""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent
ROUTE = ROOT / "bin" / "route"
RULE = REPO / ".cursor" / "rules" / "effort-routing.mdc"
WHEN = "otherwise, for non-trivial engineering"
LIFE = "a life or mission focus block, and the ask is not repo work"

# signals, effort, reason
CASES = [
    ({}, "high", "normal feature"),
    ({"kind": "feature", "files": 8, "spread": 2}, "high", "normal feature"),
    ({"kind": "build", "files": 4, "spread": 1}, "high", "normal feature"),
    ({"kind": "review", "files": 12, "spread": 3}, "high", "review"),
    ({"kind": "plan"}, "high", "planning"),
    ({"kind": "plan", "novel": True}, "xhigh", "novel planning"),
    ({"kind": "plan", "hard": True}, "xhigh", "hard planning"),
    ({"kind": "plan", "hard": True, "novel": True}, "xhigh", "hard planning"),
    ({"kind": "feature", "first_build": True}, "xhigh", "first build of a new feature"),
    ({"kind": "fix", "first_build": True, "files": 1, "spread": 1}, "medium", "routine fix"),
    ({"kind": "feature", "security": True}, "xhigh", "security"),
    ({"kind": "docs", "security": True, "files": 1, "spread": 1}, "xhigh", "security"),
    ({"kind": "feature", "data_loss": True}, "xhigh", "data-loss"),
    ({"kind": "feature", "blast": ["auth"]}, "xhigh", "blast auth"),
    ({"kind": "feature", "blast": ["money"]}, "xhigh", "blast money"),
    ({"kind": "feature", "blast": ["data"]}, "xhigh", "blast data"),
    ({"kind": "feature", "blast": ["data", "auth"]}, "xhigh", "blast auth"),
    ({"kind": "feature", "security": True, "blast": ["auth"], "first_build": True}, "xhigh", "security"),
    ({"kind": "feature", "cross_cutting": True}, "xhigh", "cross-cutting"),
    ({"kind": "feature", "spread": 4, "files": 3}, "xhigh", "cross-cutting"),
    ({"kind": "fix", "spread": 4, "files": 4}, "xhigh", "cross-cutting"),
    ({"kind": "review", "spread": 6, "files": 10}, "high", "review"),
    ({"kind": "rename", "spread": 8, "files": 40}, "low", "rename"),
    ({"kind": "feature", "reversible": False}, "xhigh", "risky"),
    ({"kind": "fix", "reversible": False, "files": 1, "spread": 1}, "xhigh", "risky"),
    ({"kind": "docs", "reversible": False, "files": 2, "spread": 1}, "low", "docs"),
    ({"kind": "fix", "files": 2, "spread": 1}, "medium", "routine fix"),
    ({"kind": "fix", "files": 20, "spread": 1}, "high", "wide diff"),
    ({"kind": "rereview", "files": 2, "spread": 1}, "low", "re-review of a small diff"),
    ({"kind": "rereview", "files": 6, "spread": 1}, "medium", "re-review"),
    ({"kind": "rereview", "files": 30, "spread": 1}, "high", "wide diff"),
    ({"kind": "docs", "files": 1, "spread": 1}, "low", "docs"),
    ({"kind": "docs", "files": 40, "spread": 1}, "low", "docs"),
    ({"kind": "rename", "files": 3, "spread": 1}, "low", "rename"),
    ({"kind": "batch", "files": 4, "spread": 2}, "low", "mechanical batch; one PR"),
    ({"kind": "feature", "blast": ["ci"]}, "high", "normal feature"),
    ({"kind": "fix", "blast": ["ci"], "files": 2, "spread": 1}, "high", "blast ci"),
    ({"kind": "docs", "blast": ["ci"], "files": 1, "spread": 1}, "medium", "blast ci"),
    ({"kind": "feature", "novel": True, "files": 6, "spread": 1}, "xhigh", "normal feature; novel"),
    ({"kind": "fix", "novel": True, "hard": True, "files": 2, "spread": 1}, "xhigh", "routine fix; novel; hard"),
    ({"kind": "docs", "novel": True, "files": 1, "spread": 1}, "medium", "docs; novel"),
    ({"kind": "feature", "pressure": True, "files": 8, "spread": 2}, "medium", "normal feature; time pressure"),
    ({"kind": "feature", "security": True, "pressure": True}, "xhigh", "security"),
    ({"kind": "docs", "pressure": True, "files": 1, "spread": 1}, "low", "docs"),
    ({"kind": "fix", "review": "REQUEST_CHANGES", "files": 2, "spread": 1}, "high", "routine fix; escalated after REQUEST_CHANGES"),
    ({"kind": "feature", "review": "request_changes"}, "xhigh", "normal feature; escalated after REQUEST_CHANGES"),
    ({"kind": "feature", "security": True, "review": "REQUEST_CHANGES"}, "xhigh", "security"),
    ({"kind": "rereview", "files": 2, "spread": 1, "review": "REQUEST_CHANGES"}, "medium", "re-review of a small diff; escalated after REQUEST_CHANGES"),
    ({"kind": "feature", "pressure": True, "review": "REQUEST_CHANGES", "files": 8, "spread": 2}, "high", "normal feature; time pressure; escalated after REQUEST_CHANGES"),
    ({"kind": "batch", "review": "REQUEST_CHANGES", "files": 3, "spread": 1}, "medium", "mechanical batch; one PR; escalated after REQUEST_CHANGES"),
    ({"kind": "review", "review": "approve"}, "high", "review"),
]


def run(args):
    return subprocess.run(
        [sys.executable, str(ROUTE), *args],
        capture_output=True,
        text=True,
    )


def fail(msg):
    print("FAIL", msg)
    return 1


def main():
    errors = 0
    for signals, effort, reason in CASES:
        proc = run(["--signals", json.dumps(signals)])
        if proc.returncode != 0:
            errors += fail("exit %s for %s: %s" % (proc.returncode, signals, proc.stderr.strip()))
            continue
        got = json.loads(proc.stdout)
        if list(got) != ["effort", "reason"]:
            errors += fail("keys %s for %s" % (list(got), signals))
            continue
        if got["effort"] != effort or got["reason"] != reason:
            errors += fail("%s -> %s want %s %s" % (signals, got, effort, reason))
            continue
        if "\n" in got["reason"] or got["effort"] not in ("low", "medium", "high", "xhigh"):
            errors += fail("shape %s" % got)
            continue
        again = run(["--signals", json.dumps(signals)])
        if again.stdout != proc.stdout:
            errors += fail("not deterministic %s" % signals)

    forward = run(["--signals", '{"kind":"docs","security":true}'])
    backward = run(["--signals", '{"security":true,"kind":"docs"}'])
    if forward.stdout != backward.stdout or json.loads(forward.stdout)["effort"] != "xhigh":
        errors += fail("key order changed the decision")

    for raw in (
        '{"kind":"nope"}',
        '{"files":-1}',
        '{"files":true}',
        '{"blast":["gpu"]}',
        '{"review":"comment"}',
        '{"novel":1}',
        '{"extra":true}',
        "[]",
        "not-json",
    ):
        proc = run(["--signals", raw])
        if proc.returncode != 2 or proc.stdout:
            errors += fail("invalid %s exited %s" % (raw, proc.returncode))

    if run([]).returncode != 2:
        errors += fail("missing args")

    card = run([WHEN, "--signals", json.dumps({"kind": "docs", "files": 1, "spread": 1})])
    if card.returncode != 0:
        errors += fail("route card exit %s %s" % (card.returncode, card.stderr.strip()))
    else:
        body = json.loads(card.stdout)
        want = ["situation", "route", "loads", "skips", "playbook", "hitl", "next", "effort", "reason"]
        if list(body) != want:
            errors += fail("card keys %s" % list(body))
        elif body["route"] != "light" or body["effort"] != "low" or body["reason"] != "docs":
            errors += fail("card mixed route and effort %s" % body)
        life = json.loads(run([LIFE, "--signals", json.dumps({"kind": "docs", "files": 1, "spread": 1})]).stdout)
        if life["route"] != "tstack" or life["effort"] != body["effort"] or life["reason"] != body["reason"]:
            errors += fail("effort followed the route id")
        plain = json.loads(run([WHEN]).stdout)
        if plain["effort"] != "high" or plain["reason"] != "normal feature":
            errors += fail("missing signals %s" % plain)

    text = RULE.read_text(encoding="utf-8") if RULE.is_file() else ""
    lines = text.splitlines()
    if not RULE.is_file():
        errors += fail("missing effort rule")
    elif len(lines) > 15:
        errors += fail("effort rule has %s lines" % len(lines))
    elif "alwaysApply: false" not in text or "alwaysApply: true" in text:
        errors += fail("effort rule apply flag")
    elif "planning" not in text.lower() or "intelli-route" not in text:
        errors += fail("effort rule description")
    elif "AI" in text:
        errors += fail("effort rule says AI")

    if errors:
        print("%s failure(s)" % errors)
        return 1
    print("ok  %s effort rows" % len(CASES))
    return 0


if __name__ == "__main__":
    sys.exit(main())
