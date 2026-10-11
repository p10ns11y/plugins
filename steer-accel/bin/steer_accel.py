#!/usr/bin/env python3
"""Stage loop and stretch watcher. No model."""

import hashlib
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

STEPS = ("question", "delete", "simplify", "accelerate", "automate")
ACTORS = {"builder", "coordinator"}
READ_TOOLS = {"read", "read_file", "beforereadfile"}
WRITE_TOOLS = {"write", "edit", "multiedit", "search_replace"}
SHELL_TOOLS = {"bash", "run_terminal_command", "beforeshellexecution"}
FIELDS = ("stage", "actor", "resumed", "card", "verify")
HOOK_ARMED = False
_STEER_LOG = None


def emit(verdict, reason, nxt):
    json.dump(
        {"verdict": verdict, "reason": reason, "next": nxt},
        sys.stdout,
    )
    sys.stdout.write("\n")
    return 0 if verdict == "admit" else 2


def allow():
    sys.stdout.write('{"decision":"allow","permission":"allow"}\n')


def deny(reason):
    json.dump(
        {
            "decision": "deny",
            "permission": "deny",
            "reason": reason,
            "agent_message": reason,
        },
        sys.stdout,
    )
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
        if len(parts) == 3:
            stage, change, verify = parts
            result, digest = "", ""
        elif len(parts) == 5:
            stage, change, verify, result, digest = parts
            if result not in ("red", "green") or not digest:
                return None, "bad stage row"
        else:
            return None, "bad stage row"
        if stage not in STEPS or not change or change == "-" or not verify:
            return None, "bad stage row"
        rows.append((stage, change, verify, result, digest))
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


def card_digest(card):
    if card in ("", "-"):
        return "-"
    path = Path(card)
    if not path.is_file():
        return "missing"
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_steer_log_module():
    global _STEER_LOG
    if _STEER_LOG:
        return _STEER_LOG
    sibling = Path(__file__).resolve().parents[2] / "steer-log" / "bin" / "steer_log.py"
    if not sibling.is_file():
        return None
    spec = importlib.util.spec_from_file_location("steer_log_card", sibling)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    _STEER_LOG = module
    return module


def load_card_checker():
    module = load_steer_log_module()
    if module is None:
        return None
    return module.check_card


def live_card_problem(card, required):
    if card in ("", "-") or not Path(card).is_file():
        return "invariant card missing" if required else None
    checker = load_card_checker()
    if checker is None:
        return "steer-log checker missing"
    return checker(Path(card).read_text(encoding="utf-8"))


def run_verify(command):
    try:
        proc = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            timeout=180,
        )
    except subprocess.TimeoutExpired:
        return None
    if proc.returncode == 0:
        return "green"
    return "red"


def evaluate(now, rows, reads, session, require_reads):
    if require_reads:
        if reads is None:
            return "refuse", "reads file is malformed", "reread"
        if not reads:
            return "refuse", "nothing read in this session", "reread"
    if now["actor"] == "coordinator" and (
        now["card"] in ("", "-") or not Path(now["card"]).is_file()
    ):
        return "refuse", "coordinator has no invariant card", "question"
    if not earned(now["stage"], rows, now["card"]):
        return "refuse", "stage is ahead of the log", blocking_step(now["stage"], rows, now["card"])
    if rows and rows[-1][3] == "red":
        if card_digest(now["card"]) == rows[-1][4]:
            return "refuse", "last verify is red and the card is unchanged", "question"
        problem = live_card_problem(now["card"], True)
        if problem:
            return "refuse", problem, "question"
    elif rows and rows[-1][0] == now["stage"] and rows[-1][2] == now["verify"]:
        return "refuse", "same stage and verify as the last row", "question"
    problem = live_card_problem(now["card"], False)
    if problem:
        return "refuse", problem, "question"
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
    result = run_verify(now["verify"])
    if result is None:
        return emit("refuse", "verify timed out", "stop")
    row = " | ".join(
        (now["stage"], now["change"], now["verify"], result, card_digest(now["card"]))
    )
    path = Path(argv[1])
    path.parent.mkdir(parents=True, exist_ok=True)
    existing = path.read_text(encoding="utf-8") if path.is_file() else ""
    if existing and not existing.endswith("\n"):
        existing += "\n"
    path.write_text(existing + row + "\n", encoding="utf-8")
    if result == "red":
        return emit("admit", "verify is red", "question")
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


def arm_hook():
    global HOOK_ARMED
    HOOK_ARMED = True


def project_root(event):
    for key in ("cwd", "workspaceRoot", "workspace_root"):
        root = event.get(key)
        if root:
            return Path(root)
    return None


def watch_armed(root):
    if (root / ".steer" / "loop.on").is_file():
        return True
    now_path = root / ".steer" / "now.md"
    if not now_path.is_file():
        return False
    for raw in now_path.read_text(encoding="utf-8").splitlines():
        if raw.strip().startswith("actor:"):
            return raw.split(":", 1)[1].strip() == "coordinator"
    return False


def file_name(path):
    return path.replace("\\", "/").rsplit("/", 1)[-1]


def prior_snapshot(path):
    return file_name(path).endswith(".prior")


def steering_doc(path):
    return file_name(path) == "steering.md"


def steer_log_file(path):
    norm = path.replace("\\", "/")
    return norm.endswith("/.steer/log.md") or norm == ".steer/log.md"


def written_text(path, tool_input):
    for key in ("contents", "content", "text"):
        value = tool_input.get(key)
        if isinstance(value, str):
            return value
    old = tool_input.get("old_string")
    if old is None:
        old = tool_input.get("oldString")
    new = tool_input.get("new_string")
    if new is None:
        new = tool_input.get("newString")
    if not isinstance(old, str) or not isinstance(new, str):
        return None
    file_path = Path(path)
    if not file_path.is_file():
        return None
    current = file_path.read_text(encoding="utf-8")
    if old not in current:
        return None
    return current.replace(old, new, 1)


def checker_command(command):
    tokens = ("steer-accel", "steer-log", "steer_accel.py", "steer_log.py")
    if not any(token in command for token in tokens):
        return False
    norm = command.replace("\\", "/")
    protected = "steering.md" in norm or ".steer/log.md" in norm or ".prior" in norm
    if protected and (">" in command or "tee" in command or "sponge" in command):
        return False
    return True


def shell_hides_protected_write(command):
    norm = command.replace("\\", "/")
    protected = "steering.md" in norm or ".steer/log.md" in norm or ".prior" in norm
    if not protected:
        return False
    return ">" in command or "tee" in command or "sponge" in command


def hidden_write_reason(command):
    if "steering.md" in command.replace("\\", "/"):
        return "steering doc write is not visible"
    return "steer log write is not visible"


def doc_write_reason(root, path, tool_input):
    module = load_steer_log_module()
    if module is None:
        return "steer-log checker missing"
    log_path = root / ".steer" / "log.md"
    if not log_path.is_file():
        return "steer log missing"
    new_text = written_text(path, tool_input)
    if new_text is None:
        return "steering doc write is not visible"
    log_text = log_path.read_text(encoding="utf-8")
    log_reason = module.parse_log(log_text)
    if log_reason:
        return log_reason
    return module.check_doc(new_text, log_text)


def log_write_reason(path, tool_input):
    module = load_steer_log_module()
    if module is None:
        return "steer-log checker missing"
    new_text = written_text(path, tool_input)
    if new_text is None:
        return "steer log write is not visible"
    file_path = Path(path)
    if file_path.is_file():
        prior_rows, reason = module.log_lines(file_path.read_text(encoding="utf-8"))
        if reason:
            return reason
    else:
        prior_rows = []
    rows, reason = module.log_lines(new_text)
    if reason:
        return reason
    return module.prefix_reason(prior_rows, rows)


def hook_event(event):
    root = project_root(event)
    tool = str(event.get("toolName") or event.get("tool_name") or "").lower()
    tool_input = event.get("toolInput") or event.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        tool_input = {}
    path = tool_path(tool_input)
    command = str(tool_input.get("command") or "")
    if checker_command(command):
        allow()
        return 0
    if tool in SHELL_TOOLS and shell_hides_protected_write(command):
        arm_hook()
        deny(hidden_write_reason(command))
        return 0
    if tool in WRITE_TOOLS and path and prior_snapshot(path):
        arm_hook()
        deny("prior snapshot is not a direct edit")
        return 0
    if root is not None and tool in WRITE_TOOLS and path and steering_doc(path):
        arm_hook()
        reason = doc_write_reason(root, path, tool_input)
        if reason:
            deny(reason)
            return 0
    if root is not None and tool in WRITE_TOOLS and path and steer_log_file(path):
        arm_hook()
        reason = log_write_reason(path, tool_input)
        if reason:
            deny(reason)
            return 0
        allow()
        return 0
    if root is None or not watch_armed(root):
        allow()
        return 0
    arm_hook()
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


def hook_main():
    try:
        raw = sys.stdin.read()
        event = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        allow()
        return 0
    try:
        return hook_event(event)
    except Exception:
        if HOOK_ARMED:
            deny("checker crashed")
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
            if HOOK_ARMED:
                deny("checker crashed")
            else:
                allow()
            sys.exit(0)
        raise
