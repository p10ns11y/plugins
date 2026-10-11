#!/usr/bin/env python3
"""Admit or refuse a builder card, a steering doc, and a pre-builder bundle. No model."""

import json
import re
import sys
from pathlib import Path

NOOP = re.compile(r"^(true|false|:|exit 0)$")
CARD_LINE = re.compile(r"^- (.+)\. Fails: `([^`]+)`\s*$")
TITLE = "# Invariant card"
HEADER = "| decision | why | verify |"
MIN_QUOTE = 12
DESIGN = re.compile(r"impeccable|superdesign|layout-content-view", re.IGNORECASE)
MODEL = re.compile(
    r"openai|anthropic|generateText|grok-|x\.ai|chat\.completions|@ai-sdk|langchain",
    re.IGNORECASE,
)
BANNED = re.compile(r"\bdemo\b|\bgate\b|the owner", re.IGNORECASE)
ADD_KEYS = re.compile(r"\badd\b.{0,40}\bkeys?\b", re.IGNORECASE | re.DOTALL)
TEAM_ID = re.compile(r"\bteam[- ]?id\b", re.IGNORECASE)
CONNECTOR = re.compile(r"^connector:\s*`([^`]+)`\s*$")
PROSE_WORD_CAP = 120
PRE_FILES = (
    ("interactions", "must-interaction tests missing"),
    ("verify", "verify script missing"),
    ("prose", "prose file missing"),
    ("writers", "writer missing"),
    ("invariant.md", "pr invariant missing"),
    ("host", "host brief missing"),
)


def emit(verdict, reason, nxt):
    json.dump({"verdict": verdict, "reason": reason, "next": nxt}, sys.stdout)
    sys.stdout.write("\n")
    return 0 if verdict == "admit" else 2


def check_card(text):
    count = 0
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line == TITLE:
            continue
        match = CARD_LINE.match(line)
        if not match:
            return "not a card line"
        sentence, command = match.group(1).strip(), match.group(2).strip()
        if not sentence:
            return "empty sentence"
        if NOOP.match(command):
            return "command cannot fail"
        count += 1
    if count == 0:
        return "no invariant lines"
    if count > 7:
        return "more than seven lines"
    return None


def card_count(text):
    count = 0
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line == TITLE:
            continue
        count += 1
    return count


def log_lines(text):
    rows = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line == HEADER:
            continue
        parts = [part.strip() for part in line.split("|")]
        if len(parts) != 5 or parts[0] or parts[4]:
            return None, "not a log row"
        decision, why, verify = parts[1], parts[2], parts[3]
        if not decision or not why:
            return None, "log row missing decision or why"
        if not (verify.startswith("`") and verify.endswith("`")):
            return None, "log verify is not a command"
        command = verify[1:-1].strip()
        if not command or NOOP.match(command):
            return None, "command cannot fail"
        rows.append(line)
    if not rows:
        return None, "log has no decisions"
    return rows, None


def parse_log(text):
    _rows, reason = log_lines(text)
    return reason


def prefix_reason(prior_rows, rows):
    if len(rows) < len(prior_rows):
        return "older decision was edited"
    for index, prior_row in enumerate(prior_rows):
        if rows[index] != prior_row:
            return "older decision was edited"
    return None


def check_doc(doc, log_text):
    quotes = []
    for raw in doc.splitlines():
        if not raw.strip():
            continue
        if not raw.startswith(">"):
            return "steering doc is not only a log quote"
        body = raw[1:].lstrip()
        if len(body) < MIN_QUOTE:
            continue
        quotes.append(body)
    if not quotes:
        return "steering doc quotes nothing from the log"
    for quote in quotes:
        if quote not in log_text:
            return "quote is not in the log"
    return None


def command_text(line):
    stripped = line.strip()
    if stripped.startswith("`") and stripped.endswith("`") and len(stripped) >= 2:
        return stripped[1:-1].strip()
    return stripped


def check_interactions(text):
    commands = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        command = command_text(line)
        if not command:
            continue
        if NOOP.match(command):
            return "command cannot fail"
        if DESIGN.search(command):
            return "design critique is not the interaction test"
        commands.append(command)
    if not commands:
        return "must-interaction tests missing"
    return None


def check_verify_script(text):
    if not text.strip():
        return "verify script missing"
    if MODEL.search(text):
        return "verify script names a model"
    if "json" not in text.lower():
        return "verify script does not print json"
    return None


def check_prose(text):
    if not text.strip():
        return "prose file missing"
    if BANNED.search(text):
        return "banned wording"
    if len(text.split()) > PROSE_WORD_CAP:
        return "prose is over 120 words"
    return None


def check_writers(text):
    rows = [line.strip() for line in text.splitlines() if line.strip()]
    if not rows:
        return "writer missing"
    if len(rows) != 1:
        return "more than one writer"
    return None


def check_pr_invariant(text):
    reason = check_card(text)
    if reason:
        return reason
    if card_count(text) != 1:
        return "pr invariant is not one line"
    return None


def check_host(text):
    if not text.strip():
        return "host brief missing"
    if ADD_KEYS.search(text):
        return "host brief asks to add keys"
    if TEAM_ID.search(text):
        return "host brief passes a team id"
    connector = None
    for raw in text.splitlines():
        match = CONNECTOR.match(raw.strip())
        if match:
            connector = match.group(1).strip()
            break
    if not connector:
        return "connector check missing"
    if NOOP.match(connector):
        return "command cannot fail"
    if "team" in connector.lower() or TEAM_ID.search(connector):
        return "host brief passes a team id"
    if DESIGN.search(connector):
        return "design critique is not the connector check"
    return None


def check_pre(directory):
    root = Path(directory)
    if not root.is_dir():
        return "pre-builder directory missing"
    texts = {}
    for name, missing in PRE_FILES:
        file_path = root / name
        if not file_path.is_file():
            return missing
        texts[name] = file_path.read_text(encoding="utf-8")
    checks = (
        check_interactions(texts["interactions"]),
        check_verify_script(texts["verify"]),
        check_prose(texts["prose"]),
        check_writers(texts["writers"]),
        check_pr_invariant(texts["invariant.md"]),
        check_host(texts["host"]),
    )
    for reason in checks:
        if reason:
            return reason
    return None


def read_path(path):
    file_path = Path(path)
    if not file_path.is_file():
        return None
    return file_path.read_text(encoding="utf-8")


def witness_path(log_path):
    return Path(str(log_path) + ".prior")


def remember(log_path, text):
    try:
        witness_path(log_path).write_text(text, encoding="utf-8")
    except OSError:
        return "prior snapshot was not recorded"
    return None


def check_log_history(text, log_path, explicit_prior):
    rows, reason = log_lines(text)
    if reason:
        return reason
    prior_file = Path(explicit_prior) if explicit_prior else None
    if prior_file is None and witness_path(log_path).is_file():
        prior_file = witness_path(log_path)
    if prior_file is None:
        return None
    prior_text = read_path(prior_file)
    if prior_text is None:
        return "prior snapshot missing"
    prior_rows, prior_reason = log_lines(prior_text)
    if prior_reason:
        return prior_reason
    return prefix_reason(prior_rows, rows)


def main(argv):
    if len(argv) < 2:
        return emit("refuse", "usage: brief|log|doc|pre", "stop")
    command = argv[1]
    if command == "brief":
        if len(argv) != 3:
            return emit("refuse", "usage: brief CARD", "stop")
        text = read_path(argv[2])
        if text is None:
            return emit("refuse", "invariant card missing", "stop")
        reason = check_card(text)
        if reason:
            return emit("refuse", reason, "stop")
        return emit("admit", "", "trust-stack")
    if command == "log":
        explicit = None
        if len(argv) == 3:
            log_path = argv[2]
        elif len(argv) == 5 and argv[3] == "--prior":
            log_path = argv[2]
            explicit = argv[4]
        else:
            return emit("refuse", "usage: log LOG [--prior PRIOR]", "stop")
        text = read_path(log_path)
        if text is None:
            return emit("refuse", "steer log missing", "stop")
        reason = check_log_history(text, log_path, explicit)
        if reason:
            return emit("refuse", reason, "stop")
        recorded = remember(log_path, text)
        if recorded:
            return emit("refuse", recorded, "stop")
        return emit("admit", "", "stop")
    if command == "doc":
        if len(argv) != 5 or argv[3] != "--log":
            return emit("refuse", "usage: doc DOC --log LOG", "stop")
        doc = read_path(argv[2])
        log_text = read_path(argv[4])
        if doc is None:
            return emit("refuse", "steering doc missing", "stop")
        if log_text is None:
            return emit("refuse", "steer log missing", "stop")
        log_reason = parse_log(log_text)
        if log_reason:
            return emit("refuse", log_reason, "stop")
        reason = check_doc(doc, log_text)
        if reason:
            return emit("refuse", reason, "stop")
        return emit("admit", "", "stop")
    if command == "pre":
        if len(argv) != 3:
            return emit("refuse", "usage: pre DIR", "stop")
        reason = check_pre(argv[2])
        if reason:
            return emit("refuse", reason, "stop")
        return emit("admit", "", "trust-stack")
    return emit("refuse", "unknown command", "stop")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
