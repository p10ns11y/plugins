#!/usr/bin/env python3
"""Stage loop and opt-in watcher. No model."""

import json
import sys
from pathlib import Path

STEPS = ("question", "delete", "simplify", "accelerate", "automate")
ACTORS = {"builder", "coordinator"}
READ_TOOLS = {"read", "read_file", "beforereadfile"}
WRITE_TOOLS = {"write", "edit", "multiedit", "search_replace"}
SHELL_TOOLS = {"bash", "run_terminal_command", "beforeshellexecution"}
FIELDS = ("stage", "actor", "resumed", "card", "verify")


def emit(verdict, reason, nxt):
    json.dump(
        {"verdict": verdict, "reason": reason, "next": nxt},
        sys.stdout,
    )
    sys.stdout.write("\n")
    return 0 if verdict == "admit" else 2


def allow():
    sys.stdout.write('{"decision":"allow"}\n')


def deny(reason):
    json.dump({"decision": "deny", "reason": reason}, sys.stdout)
    sys.stdout.write("\n")


def parse_now(text):
    data = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            return None, "not a field"
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip()
    for key in FIELDS:
        if key not in data or data[key] == "":
            return None, "missing " + key
    if data["stage"] not in STEPS:
        return None, "unknown stage"
    if data["actor"] not in ACTORS:
        return None, "unknown actor"
    if data["resumed"] not in ("yes", "no"):
        return None, "resumed must be yes or no"
    if "change" not in data or data["change"] == "":
        data["change"] = "-"
    return data, None


def parse_log(text):
    rows = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        parts = [part.strip() for part in line.split("|")]
        if len(parts) != 3:
            return None, "bad stage row"
        stage, change, verify = parts
        if stage not in STEPS or not change or change == "-" or not verify:
            return None, "bad stage row"
        rows.append((stage, change, verify))
    return rows, None


def earned(stage, rows, card):
    has_card = card not in ("", "-")
    seen = {row[0] for row in rows}
    if stage == "question":
        return True
    if not has_card:
        return False
    if stage in ("delete", "simplify"):
        return True
    if stage == "accelerate":
        return bool(seen & {"delete", "simplify"})
    if stage == "automate":
        return "delete" in seen and "simplify" in seen
    return False


def blocking_step(stage, rows, card):
    seen = {row[0] for row in rows}
    has_card = card not in ("", "-")
    if not has_card:
        return "question"
    if stage == "accelerate" and not (seen & {"delete", "simplify"}):
        return "delete"
    if stage == "automate" and "delete" not in seen:
        return "delete"
    if stage == "automate" and "simplify" not in seen:
        return "simplify"
    return "question"


def session_reads(text, session):
    found = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if "\t" not in line:
            return None
        sid, path = line.split("\t", 1)
        path = path.strip()
        if not path or "/.steer/" in path or path.startswith(".steer/"):
            continue
        if session is None or sid == session:
            found.append(path)
    return found


def evaluate(now, rows, reads, session, require_reads):
    if require_reads:
        if reads is None:
            return "refuse", "reads file is malformed", "reread"
        if not reads:
            return "refuse", "nothing read in this session", "reread"
    if now["actor"] == "coordinator" and now["card"] in ("", "-"):
        return "refuse", "coordinator has no invariant card", "question"
    if not earned(now["stage"], rows, now["card"]):
        return "refuse", "stage is ahead of the log", blocking_step(now["stage"], rows, now["card"])
    if rows and rows[-1][0] == now["stage"] and rows[-1][2] == now["verify"]:
        return "refuse", "same stage and verify as the last row", "question"
    return "admit", "", now["stage"]


def load_pair(now_path, log_path):
    now_file = Path(now_path)
    if not now_file.is_file():
        return None, None, "now.md missing"
    now, reason = parse_now(now_file.read_text(encoding="utf-8"))
    if reason:
        return None, None, reason
    log_file = Path(log_path) if log_path else None
    if log_file is None or not log_file.is_file():
        rows = []
    else:
        rows, reason = parse_log(log_file.read_text(encoding="utf-8"))
        if reason:
            return None, None, reason
    return now, rows, None


def flag(argv, name):
    if name not in argv:
        return None
    index = argv.index(name)
    if index + 1 >= len(argv):
        return ""
    return argv[index + 1]


def positional(argv):
    skip = set()
    for name in ("--reads", "--session"):
        if name in argv:
            index = argv.index(name)
            skip.add(index)
            skip.add(index + 1)
    return [arg for i, arg in enumerate(argv) if i not in skip]


def check_cmd(argv):
    args = positional(argv)
    if len(args) < 1:
        return emit("refuse", "usage: check NOW [LOG]", "stop")
    now, rows, reason = load_pair(args[0], args[1] if len(args) > 1 else None)
    if reason:
        return emit("refuse", reason, "stop")
    reads_path = flag(argv, "--reads")
    session = flag(argv, "--session")
    require = reads_path is not None
    reads = None
    if require:
        path = Path(reads_path)
        text = path.read_text(encoding="utf-8") if path.is_file() else ""
        reads = session_reads(text, session if session else None)
    verdict, why, nxt = evaluate(now, rows, reads, session, require)
    return emit(verdict, why, nxt)


def append_cmd(argv):
    if len(argv) != 2:
        return emit("refuse", "usage: append NOW LOG", "stop")
    now, rows, reason = load_pair(argv[0], argv[1])
    if reason:
        return emit("refuse", reason, "stop")
    verdict, why, nxt = evaluate(now, rows, None, None, False)
    if verdict != "admit":
        return emit(verdict, why, nxt)
    if now["change"] in ("", "-"):
        return emit("refuse", "nothing to record", "stop")
    row = " | ".join((now["stage"], now["change"], now["verify"]))
    path = Path(argv[1])
    path.parent.mkdir(parents=True, exist_ok=True)
    existing = path.read_text(encoding="utf-8") if path.is_file() else ""
    if existing and not existing.endswith("\n"):
        existing += "\n"
    path.write_text(existing + row + "\n", encoding="utf-8")
    return emit("admit", "", now["stage"])


def reset_reads(argv):
    if len(argv) != 1:
        return emit("refuse", "usage: reset-reads FILE", "stop")
    path = Path(argv[0])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("", encoding="utf-8")
    return emit("admit", "", "reread")


def tool_path(tool_input):
    if not isinstance(tool_input, dict):
        return ""
    for key in ("file_path", "target_file", "path", "filePath"):
        value = tool_input.get(key)
        if value:
            return str(value)
    return ""


def under_steer(path):
    norm = path.replace("\\", "/")
    return "/.steer/" in norm or norm.startswith(".steer/") or norm.endswith("/.steer")


def loop_root(event):
    for key in ("cwd", "workspaceRoot", "workspace_root"):
        root = event.get(key)
        if root and Path(root, ".steer", "loop.on").is_file():
            return Path(root)
    return None


def hook_main():
    try:
        raw = sys.stdin.read()
        event = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        allow()
        return 0
    root = loop_root(event)
    if root is None:
        allow()
        return 0
    tool = str(event.get("toolName") or event.get("tool_name") or "").lower()
    tool_input = event.get("toolInput") or event.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        tool_input = {}
    path = tool_path(tool_input)
    command = str(tool_input.get("command") or "")
    if any(token in command for token in ("steer-accel", "steer-log", "steer_accel.py", "steer_log.py")):
        allow()
        return 0
    session = str(event.get("sessionId") or event.get("session_id") or "none")
    if tool in READ_TOOLS:
        if path and not under_steer(path):
            reads = root / ".steer" / "reads"
            reads.parent.mkdir(parents=True, exist_ok=True)
            with reads.open("a", encoding="utf-8") as handle:
                handle.write(session + "\t" + path + "\n")
        allow()
        return 0
    if tool not in WRITE_TOOLS and tool not in SHELL_TOOLS:
        allow()
        return 0
    if path and under_steer(path):
        allow()
        return 0
    now_path = root / ".steer" / "now.md"
    log_path = root / ".steer" / "stage.log"
    if not now_path.is_file():
        deny("loop is on and now.md is missing")
        return 0
    now, rows, reason = load_pair(str(now_path), str(log_path))
    if reason:
        deny(reason)
        return 0
    reads_path = root / ".steer" / "reads"
    text = reads_path.read_text(encoding="utf-8") if reads_path.is_file() else ""
    reads = session_reads(text, session)
    verdict, why, _nxt = evaluate(now, rows, reads, session, True)
    if verdict != "admit":
        deny(why)
        return 0
    allow()
    return 0


def main(argv):
    if len(argv) < 2:
        return emit("refuse", "usage: check|append|reset-reads|hook", "stop")
    command = argv[1]
    rest = argv[2:]
    if command == "check":
        return check_cmd(rest)
    if command == "append":
        return append_cmd(rest)
    if command == "reset-reads":
        return reset_reads(rest)
    if command == "hook":
        return hook_main()
    return emit("refuse", "unknown command", "stop")


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except Exception:
        if len(sys.argv) > 1 and sys.argv[1] == "hook":
            allow()
            sys.exit(0)
        raise
