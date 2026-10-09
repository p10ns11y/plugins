#!/usr/bin/env python3
"""Admit or refuse a builder card and a steering doc. No model."""

import json
import re
import sys
from pathlib import Path

NOOP = re.compile(r"^(true|false|:|exit 0)$")
CARD_LINE = re.compile(r"^- (.+)\. Fails: `([^`]+)`\s*$")
TITLE = "# Invariant card"
HEADER = "| decision | why | verify |"
MIN_QUOTE = 12


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


def parse_log(text):
    rows = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line == HEADER:
            continue
        parts = [part.strip() for part in line.split("|")]
        if len(parts) != 5 or parts[0] or parts[4]:
            return "not a log row"
        decision, why, verify = parts[1], parts[2], parts[3]
        if not decision or not why:
            return "log row missing decision or why"
        if not (verify.startswith("`") and verify.endswith("`")):
            return "log verify is not a command"
        command = verify[1:-1].strip()
        if not command or NOOP.match(command):
            return "command cannot fail"
        rows.append(line)
    if not rows:
        return "log has no decisions"
    return None


def check_doc(doc, log_text):
    quotes = []
    for raw in doc.splitlines():
        if not raw.startswith(">"):
            continue
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


def read_path(path):
    file_path = Path(path)
    if not file_path.is_file():
        return None
    return file_path.read_text(encoding="utf-8")


def main(argv):
    if len(argv) < 2:
        return emit("refuse", "usage: brief|log|doc", "stop")
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
        if len(argv) != 3:
            return emit("refuse", "usage: log LOG", "stop")
        text = read_path(argv[2])
        if text is None:
            return emit("refuse", "steer log missing", "stop")
        reason = parse_log(text)
        if reason:
            return emit("refuse", reason, "stop")
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
    return emit("refuse", "unknown command", "stop")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
