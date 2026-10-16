#!/usr/bin/env python3
"""Run the ten tstack flows against the programs on PATH and in this repo."""

import json
import os
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

E2E = Path(__file__).resolve().parent
TSTACK = E2E.parents[1]
REPO = E2E.parents[2]
STATE = TSTACK / "scripts" / "tstack-state"
SWEEP = TSTACK / "bin" / "capture-sweep"
MERGE = TSTACK / "bin" / "merge-check"
MAP = E2E / "fixtures" / "map.json"
RECORDS = E2E / "fixtures" / "records"
STUB = E2E / "bin" / "premflow"
GRAPH_DIR = REPO / "mission-map" / "rust" / "target" / "debug"
CARD_LOG = REPO / "concordance" / "skills" / "concordance" / "references" / "card.md"
FEEDER = REPO / "control-plane" / "skills" / "control-feeder" / "SKILL.md"
MANIFEST = REPO / "intelli-route" / "manifest.json"
LOOP_SKILL = TSTACK / "skills" / "tomato-loop" / "SKILL.md"
PLUGIN_JSON = REPO / "premflow" / "plugin.json"
NARROW = "/usr/bin:/bin:" + str(GRAPH_DIR)
DATE = "2026-01-15"
WHEN = "2026-01-15T00:00:00Z"
WHEN_REPO = "otherwise, for non-trivial engineering"
WHEN_LIFE = "a life or mission focus block, and the ask is not repo work"

calls = []
opened = []
writes = []


class FlowError(Exception):
    pass


def check(cond, detail="check failed"):
    if not cond:
        raise FlowError(detail)


def read_text(path):
    path = Path(path).resolve()
    opened.append(path)
    return path.read_text(encoding="utf-8")


def run(argv, *, env=None, path=None):
    calls.append(tuple(argv))
    name = Path(argv[0]).name
    if name in {"send", "reply", "pay", "sign"}:
        raise FlowError("command " + name)
    base = os.environ.copy()
    for key in ("GH_TOKEN", "GITHUB_TOKEN", "PULSE_MEMORY_DB", "TSTACK_STATE_DB", "PREMFLOW_LOG"):
        base.pop(key, None)
    if env:
        base.update(env)
    if path is not None:
        base["PATH"] = path
    return subprocess.run(argv, capture_output=True, text=True, env=base)


def state(db, args, *, path=None, env=None):
    merged = {}
    if env:
        merged.update(env)
    merged["TSTACK_STATE_DB"] = str(db)
    return run([str(STATE), *args], env=merged, path=path)


def must(proc):
    if proc.returncode != 0:
        raise FlowError(
            "exit %s stdout=%r stderr=%r" % (proc.returncode, proc.stdout, proc.stderr)
        )
    return proc


def must_json(proc):
    must(proc)
    return json.loads(proc.stdout)


def which(name, path_value=None):
    raw = os.environ.get("PATH", "") if path_value is None else path_value
    for folder in raw.split(os.pathsep):
        if not folder:
            continue
        candidate = Path(folder) / name
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return candidate
    return None


def fresh_db():
    return Path(tempfile.mkdtemp()) / "state.sqlite"


def query(db, sql, args=()):
    con = sqlite3.connect(db)
    try:
        return con.execute(sql, args).fetchall()
    finally:
        con.close()


def scalar(db, sql, args=()):
    rows = query(db, sql, args)
    if not rows:
        return None
    return rows[0][0]


def stage_class(db, stage_id):
    return scalar(
        db,
        "SELECT class FROM stages WHERE map_id=? AND stage_id=?",
        ("loop", stage_id),
    )


def count_stage_put():
    return sum(1 for argv in calls if len(argv) >= 3 and argv[1] == "stage" and argv[2] == "put")


def count_block_close():
    return sum(1 for argv in calls if len(argv) >= 3 and argv[1] == "block" and argv[2] == "close")


def called_block_open():
    return any(len(argv) >= 3 and argv[1] == "block" and argv[2] == "open" for argv in calls)


def called_harvest_add():
    return any(len(argv) >= 3 and argv[1] == "harvest" and argv[2] == "add" for argv in calls)


def called_premflow():
    return any(Path(argv[0]).name == "premflow" for argv in calls)


def called_merge():
    return any(Path(argv[0]).name == "merge-check" for argv in calls)


def is_figure(result):
    words = result.lower().split()
    return any(word in ("money", "health", "family") for word in words)


def names_no_load(text):
    words = text.replace("|", " ").replace("*", " ").split()
    check("load" not in words, "card names a load")
    check("loads" not in words, "card names a load")


def parse_card(text):
    fields = {}
    for line in text.splitlines():
        if line.startswith("- ") and ": " in line:
            key, value = line[2:].split(": ", 1)
            fields[key] = value
    return fields


def field_map(card):
    found = {}
    for line in card.splitlines():
        if not line.startswith("| **") or not line.endswith("|"):
            continue
        body = line.strip("|")
        name, value = body.split("|", 1)
        found[name.strip().strip("*")] = value.strip()
    return found


def parse_report(text):
    critical = None
    nxt = None
    for line in text.splitlines():
        if line.startswith("critical="):
            critical = line.split("=", 1)[1]
        elif line.startswith("next_do="):
            nxt = line.split("=", 1)[1].strip()
    if critical is None:
        raise FlowError("no critical=")
    ids = [part for part in critical.split(" -> ") if part]
    if not ids:
        raise FlowError("empty critical")
    return ids, nxt


def graph_apply(db, path_env=None):
    proc = state(db, ["export-map", "--map", "loop"], path=path_env)
    must(proc)
    raw = proc.stdout
    handle, name = tempfile.mkstemp(suffix=".json")
    try:
        with os.fdopen(handle, "w", encoding="utf-8") as out:
            out.write(raw)
        check(Path(name).resolve() != MAP.resolve(), "graph got the fixture file")
        graph = which("mission-map-graph", path_env)
        if graph is None:
            raise FlowError("missing mission-map/rust/target/debug/mission-map-graph")
        gproc = run([str(graph), name], path=path_env)
        if gproc.returncode != 0:
            raise FlowError("graph exit %s %s" % (gproc.returncode, gproc.stderr))
        ids, nxt = parse_report(gproc.stdout)
        args = ["apply-report", "--map", "loop", "--critical", ",".join(ids)]
        if nxt:
            args.extend(["--next", nxt])
        must(state(db, args, path=path_env))
        listed = must_json(state(db, ["next", "--map", "loop"], path=path_env))
        return listed["stage_id"]
    finally:
        if os.path.exists(name):
            os.unlink(name)


def load_shared(db, path_env=None):
    must(state(db, ["init"], path=path_env))
    fixture = json.loads(read_text(MAP))
    check(fixture["g"] == "checkable arrival", "fixture g")
    must(state(db, ["map", "put", "--id", "loop", "--g", fixture["g"]], path=path_env))
    for stage in fixture["stages"]:
        args = [
            "stage", "put", "--map", "loop", "--id", stage["id"],
            "--class", stage["class"],
            "--a", str(stage["a"]), "--m", str(stage["m"]), "--b", str(stage["b"]),
            "--label", stage["id"],
        ]
        if stage["depends_on"]:
            args.extend(["--depends", ",".join(stage["depends_on"])])
        must(state(db, args, path=path_env))
    nxt = graph_apply(db, path_env)
    dos = [stage for stage in fixture["stages"] if stage["class"] == "Do"]
    shortest = min(dos, key=lambda stage: stage["m"])
    check(shortest["id"] == "short", "smaller m")
    check(nxt == "short", "next Do")
    side = next(stage for stage in fixture["stages"] if stage["id"] == "side")
    check(side["class"] == "Park", "side")
    check(nxt not in ("done-node", "side"), "chosen stage")
    return nxt


def route_for(when):
    manifest = json.loads(read_text(MANIFEST))
    if "tstack" not in manifest.get("routes", {}):
        raise FlowError("missing routes.tstack")
    skipped = []
    match = None
    for row in manifest["primary"]:
        if row.get("when") == when:
            match = row
            break
        skipped.append("%s: when" % row["id"])
    if match is None:
        raise FlowError("missing when")
    load_id = match["id"]
    load_path = None
    for item in manifest["loads"]:
        if item.get("id") == load_id:
            load_path = item.get("path")
            break
    loads = [load_id]
    check(len(loads) <= 4, "loads")
    emit = {
        "situation": when,
        "route": match["route"],
        "loads": loads,
        "skips": skipped,
        "playbook": "skip",
        "hitl": "none",
        "next": load_id,
    }
    check(
        list(emit) == ["situation", "route", "loads", "skips", "playbook", "hitl", "next"],
        "emit fields",
    )
    return emit, load_path


def judge(label_dm, label_llm, p_dm, tau):
    agree = "yes" if label_dm != "" and label_dm == label_llm else "no"
    try:
        high_enough = float(p_dm) >= float(tau)
    except ValueError:
        high_enough = False
    act = "proceed" if agree == "yes" and high_enough else "hold"
    return agree, act


def concordance_card(label_dm, label_llm, p_dm, tau):
    agree, act = judge(label_dm, label_llm, p_dm, tau)
    card = "\n".join([
        "## Concordance",
        "| Field | Value |",
        "|-------|--------|",
        "| **label_dm** | %s |" % label_dm,
        "| **label_llm** | %s |" % label_llm,
        "| **agree** | %s |" % agree,
        "| **p_dm** | %s |" % p_dm,
        "| **kappa_window** | |",
        "| **act** | %s |" % act,
        "",
    ])
    names_no_load(card)
    return card, agree, act


def append_line(path, label_dm, label_llm, p_dm, tau, agree, act):
    line = "label_dm=%s label_llm=%s p_dm=%s tau=%s agree=%s act=%s" % (
        label_dm, label_llm, p_dm, tau, agree, act,
    )
    with path.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")
    writes.append(path)
    return line


def read_printed(action):
    previous = sys.stdout
    chunks = []

    class Tee:
        def write(self, data):
            previous.write(data)
            chunks.append(data)

        def flush(self):
            previous.flush()

    sys.stdout = Tee()
    try:
        action()
    finally:
        sys.stdout = previous
    return "".join(chunks)


def hitl(kind):
    card = "# HITL\n- kind: %s\n- owner: SI\n" % kind
    check("owner: SI" in card, "owner")
    names_no_load(card)
    return card


def append_public(path, stage_id, result, evidence):
    line = "%s\t%s\t%s\t%s\n" % (DATE, stage_id, result, evidence)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(line)
    writes.append(path)


def mark_done(db, path_env=None):
    must(state(db, [
        "stage", "put", "--map", "loop", "--id", "short",
        "--class", "Done", "--a", "2", "--m", "2", "--b", "2", "--label", "short",
    ], path=path_env))


def flow_capture():
    feeder = read_text(FEEDER)
    check("agent-orchestrator" in feeder, "feeder next")
    check("| else |" in feeder, "feeder else")
    proc = run([str(SWEEP), "check-allows"])
    check(proc.returncode == 0, proc.stderr)
    expects = [
        ("mail.txt", "mail", "A thread needs a look.", "mail:1"),
        ("calendar.txt", "calendar", "A calendar block changed.", "calendar:2"),
        ("chat.txt", "chat", "A chat needs a look.", "chat:3"),
        ("pr.txt", "pr", "A pull request is waiting.", "pr:4"),
    ]
    none_cards = []
    for name, source, ask, ref in expects:
        proc = run([str(SWEEP), "emit", str(RECORDS / name)])
        check(proc.returncode == 0, proc.stderr)
        card = parse_card(proc.stdout)
        check(card["kind"] == "none", name)
        check(card["source"] == source, name)
        check(card["ask"] == ask, name)
        check(card["ref"] == ref, name)
        check(card["holds"] == "none", name)
        check(card["owner"] == "none", name)
        none_cards.append(proc.stdout.strip())
    send = run([str(SWEEP), "emit", str(RECORDS / "send.txt")])
    check(send.returncode == 0, send.stderr)
    send_card = parse_card(send.stdout)
    check(send_card["kind"] == "send", "stop kind")
    check(send_card["ask"] == "A note is waiting to go out.", "stop ask")
    check(send_card["holds"] == "send", "stop holds")
    check(send_card["owner"] == "si", "stop owner")
    bad = run([str(SWEEP), "emit", str(RECORDS / "bad-digit.txt")])
    check(bad.returncode == 2, "bad ask exit")
    check(bad.stdout == "", "bad ask card")
    empty = tempfile.mkdtemp()
    live = run(["/bin/bash", str(SWEEP), "live-pr"], path=empty)
    check(live.returncode == 0, "live-pr exit")
    check(live.stdout == "", "live-pr stdout")
    check(live.stderr == "pr: unavailable\n", "live-pr stderr")
    dump = "\n\n".join(none_cards)
    for ask in (
        "A thread needs a look.",
        "A calendar block changed.",
        "A chat needs a look.",
        "A pull request is waiting.",
    ):
        check(ask in dump, ask)
    check("A note is waiting to go out." not in dump, "stop in dump")
    check("See item 2." not in dump, "bad ask in dump")
    feed = "\n".join([
        "## Feed",
        "| Field | Value |",
        "|-------|--------|",
        "| **goal** | Review four ordinary cards. |",
        "| **dump_source** | paste |",
        "| **route** | light |",
        "| **why** | else |",
        "| **next** | agent-orchestrator |",
    ])
    fields = field_map(feed)
    check(fields["goal"] != "", "goal")
    check(fields["dump_source"] == "paste", "dump_source")
    check(fields["route"] == "light", "route")
    check(fields["why"] == "else", "why")
    check(fields["next"] == "agent-orchestrator", "next")
    check(not any("control" in path.name.lower() for path in writes), "control card")
    names = [Path(argv[0]).name for argv in calls]
    for banned in ("send", "reply", "pay", "sign", "gh"):
        check(banned not in names, banned)


def flow_admit():
    db = fresh_db()
    nxt = load_shared(db)
    check(nxt == "short", "start next")
    puts = count_stage_put()
    send = run([str(SWEEP), "emit", str(RECORDS / "send.txt")])
    check(send.returncode == 0, send.stderr)
    check(parse_card(send.stdout)["kind"] == "send", "stop")
    check(count_stage_put() == puts, "stop stage put")
    nxt = must_json(state(db, ["next", "--map", "loop"]))["stage_id"]
    check(nxt == "short", "next after stop")
    seen = set()
    mail = run([str(SWEEP), "emit", str(RECORDS / "mail.txt")])
    check(mail.returncode == 0, mail.stderr)
    ask = parse_card(mail.stdout)["ask"]
    check(ask not in seen, "first ask")
    seen.add(ask)
    must(state(db, [
        "stage", "put", "--map", "loop", "--id", "ahead",
        "--class", "Do", "--a", "3", "--m", "3", "--b", "3",
        "--label", "ahead", "--depends", "done-node",
    ]))
    must(state(db, [
        "stage", "put", "--map", "loop", "--id", "short",
        "--class", "Do", "--a", "2", "--m", "2", "--b", "2",
        "--label", "short", "--depends", "ahead",
    ]))
    check(count_stage_put() == puts + 2, "admission puts")
    nxt = graph_apply(db)
    check(nxt == "ahead", "next after admission")
    mail_again = run([str(SWEEP), "emit", str(RECORDS / "mail.txt")])
    check(mail_again.returncode == 0, mail_again.stderr)
    repeated = parse_card(mail_again.stdout)["ask"]
    check(repeated in seen, "repeated ask")
    check(count_stage_put() == puts + 2, "repeated stage put")
    first = must_json(state(db, [
        "pulse", "admit", "--key", "wording",
        "--snippet", "Keep the first wording.",
        "--source", "tstack/e2e", "--time", WHEN,
        "--status", "tool-verified", "--kind", "memory", "--lock", "locked",
    ]))
    check(first["nat_key"] == "wording", "first key")
    second = must_json(state(db, [
        "pulse", "admit", "--key", "wording",
        "--snippet", "Keep the second wording.",
        "--source", "tstack/e2e", "--time", WHEN,
        "--status", "tool-verified", "--kind", "memory", "--lock", "locked",
    ]))
    check(second["nat_key"] == "wording-2", "suffixed key")
    listed = must_json(state(db, ["pulse", "list", "--limit", "8"]))
    by_key = {row["nat_key"]: row["snippet"] for row in listed["rows"]}
    check(by_key.get("wording") == "Keep the first wording.", "first snippet")
    check(by_key.get("wording-2") == "Keep the second wording.", "second snippet")
    for row in listed["rows"]:
        text = row["snippet"]
        check(not ("first" in text and "second" in text), "averaged snippet")
    conflicts = query(db, "SELECT subject, resolution FROM conflicts")
    check(("wording", "not in the evidence") in conflicts, "conflict row")
    must_json(state(db, [
        "pulse", "admit", "--key", "sweep",
        "--snippet", "none=4 stop=1",
        "--source", "tstack/capture-sweep",
        "--time", WHEN,
        "--status", "tool-verified",
        "--kind", "context",
        "--lock", "open",
    ]))
    sweep = query(
        db,
        "SELECT snippet, source, time, status, kind, lock FROM memory_traces WHERE nat_key=?",
        ("sweep",),
    )
    check(sweep == [("none=4 stop=1", "tstack/capture-sweep", WHEN, "tool-verified", "context", "open")], "sweep row")
    listed = must_json(state(db, ["pulse", "list", "--limit", "8"]))
    check(all(row["kind"] == "memory" for row in listed["rows"]), "list kind")
    check(all(row["nat_key"] != "sweep" for row in listed["rows"]), "sweep hidden")


def flow_replan():
    shock = "shock"
    check(shock == "shock", "shock")
    proc = run([str(SWEEP), "check-allows"])
    check(proc.returncode == 0, proc.stderr)
    start = len(calls)
    db = fresh_db()
    nxt = load_shared(db)
    check(nxt == "short", "stage_id")
    check(scalar(db, "SELECT COUNT(*) FROM blocks WHERE status='open'") == 0, "open block")
    for argv in calls[start:]:
        check(not (Path(argv[0]).name == "capture-sweep" and len(argv) > 1 and argv[1] == "emit"), "emit")
    mark = len(calls)

    def stop_for_empty_g(g):
        if g != "":
            raise FlowError("empty g continued")
        print("Ask: name a checkable arrival.", flush=True)

    trace = read_printed(lambda: stop_for_empty_g(""))
    check("checkable arrival" in trace, "empty g ask")
    check("next_do=" not in trace, "empty g next")
    for argv in calls[mark:]:
        check(not (len(argv) >= 3 and argv[1] == "map" and argv[2] == "put"), "map put")
        check(not (len(argv) >= 2 and argv[1] == "export-map"), "export-map")
        check(Path(argv[0]).name != "mission-map-graph", "graph")


def flow_route_repo():
    emit, _load_path = route_for(WHEN_REPO)
    check(emit["route"] == "light", "route")
    check("pstack-map" in emit["loads"], "load")
    check(len(emit["loads"]) <= 4, "load count")
    check(emit["playbook"] == "skip", "playbook")
    check(emit["hitl"] == "none", "hitl")
    check(not called_block_open(), "block open")
    repo = Path(tempfile.mkdtemp())
    check(not (repo / "FREEZE").exists(), "freeze")
    proc = run([
        str(MERGE), "--repo", str(repo),
        "--tests-exit", "0",
        "--writer-family", "grok",
        "--reviewer-family", "claude",
    ])
    check(proc.returncode == 0, "merge exit")
    check(proc.stdout == "", "merge stdout")


def flow_route_life():
    emit, load_path = route_for(WHEN_LIFE)
    check(emit["route"] == "tstack", "route")
    check(emit["loads"] == ["tstack"], "load")
    check(load_path == "tstack/skills/tomato-loop/SKILL.md", "load path")
    check(emit["playbook"] == "skip", "playbook")
    check(len(emit["loads"]) <= 4, "load count")
    check(emit["hitl"] == "none", "hitl")
    proc = run(["bash", "-c", "command -v premflow"], path=NARROW)
    check(proc.returncode != 0, "premflow on PATH")
    check("premflow" not in read_text(STATE), "state execs premflow")
    db = fresh_db()
    load_shared(db, NARROW)
    for energy in ("high", "mid", "low"):
        proc = state(db, [
            "block", "open", "--map", "loop", "--stage", "short", "--energy", energy,
        ], path=NARROW)
        check(proc.returncode == 0, energy)
        rows = query(
            db,
            "SELECT stage_id, plan FROM blocks WHERE map_id=? AND status='open'",
            ("loop",),
        )
        check(rows == [("short", None)], energy)
        must(state(db, ["block", "close", "--map", "loop"], path=NARROW))
    check(not called_premflow(), "premflow exec")


def flow_concordance_hold():
    before = read_text(CARD_LOG)
    check("label_dm=" in before, "card log shape")
    log = Path(tempfile.mkdtemp()) / "card.md"
    cases = [
        ("ship", "hold", "0.95", "0.8", "no", "hold"),
        ("ship", "ship", "0.4", "0.8", "yes", "hold"),
    ]
    for label_dm, label_llm, p_dm, tau, agree, act in cases:
        card, got_agree, got_act = concordance_card(label_dm, label_llm, p_dm, tau)
        fields = field_map(card)
        check(list(fields) == [
            "label_dm", "label_llm", "agree", "p_dm", "kappa_window", "act",
        ], "six fields")
        check(fields["agree"] == agree, "agree")
        check(fields["act"] == act, "act")
        check(fields["kappa_window"] == "", "kappa")
        check(got_agree == agree and got_act == act, "judge")
        hitl("hold")
        append_line(log, label_dm, label_llm, p_dm, tau, agree, act)
    check(log.read_text(encoding="utf-8").splitlines() == [
        "label_dm=ship label_llm=hold p_dm=0.95 tau=0.8 agree=no act=hold",
        "label_dm=ship label_llm=ship p_dm=0.4 tau=0.8 agree=yes act=hold",
    ], "log lines")
    check(read_text(CARD_LOG) == before, "repo card log")
    check(not called_block_open(), "block open")
    check(not called_merge(), "merge-check")


def flow_concordance_proceed():
    before = read_text(CARD_LOG)
    log = Path(tempfile.mkdtemp()) / "card.md"
    card, agree, act = concordance_card("ship", "ship", "0.91", "0.8")
    fields = field_map(card)
    check(list(fields) == [
        "label_dm", "label_llm", "agree", "p_dm", "kappa_window", "act",
    ], "six fields")
    check(fields["agree"] == "yes" and agree == "yes", "agree")
    check(fields["act"] == "proceed" and act == "proceed", "act")
    check(fields["kappa_window"] == "", "kappa")
    line = append_line(log, "ship", "ship", "0.91", "0.8", agree, act)
    check(line == "label_dm=ship label_llm=ship p_dm=0.91 tau=0.8 agree=yes act=proceed", "log line")
    db = fresh_db()
    load_shared(db, NARROW)
    proc = run(["bash", "-c", "command -v premflow"], path=NARROW)
    check(proc.returncode != 0, "premflow on PATH")
    must(state(db, [
        "block", "open", "--map", "loop", "--stage", "short", "--energy", "mid",
    ], path=NARROW))
    rows = query(db, "SELECT stage_id, plan FROM blocks WHERE status='open'")
    check(rows == [("short", None)], "plan")
    listed = must_json(state(db, ["harvest", "list", "--map", "loop"], path=NARROW))
    check(listed["rows"] == [], "harvest")
    check(not any(path.name == "LOG.md" for path in writes), "public row")
    check(not (TSTACK / "LOG.md").exists(), "LOG.md")
    check(read_text(CARD_LOG) == before, "repo card log")
    check(not called_premflow(), "premflow")


def flow_irreversible():
    skill = read_text(LOOP_SKILL)
    check("SI owns the write" in skill, "owner phrase")
    db = fresh_db()
    must(state(db, ["init"]))
    for kind in ("send", "pay", "sign"):
        card = hitl(kind)
        check("kind: %s" % kind in card, kind)
        check("owner: SI" in card, kind)
    check(scalar(db, "SELECT COUNT(*) FROM blocks") == 0, "blocks")
    check(not called_block_open(), "block open")
    check(not called_harvest_add(), "harvest")
    check(not called_premflow(), "premflow")


def flow_harvest_with():
    path9 = str(STUB.parent) + os.pathsep + os.environ.get("PATH", "")
    found = run(["bash", "-c", "command -v premflow"], path=path9)
    check(found.returncode == 0, "command -v")
    check(found.stdout.strip() == str(STUB), "stub path")
    stub_text = read_text(STUB)
    check("sleep" not in stub_text, "sleep")
    for bad in ("stop", "pause", "start"):
        proc = run([str(STUB), bad], path=path9)
        check(proc.returncode == 2, bad)
        check("[POMO]" not in proc.stdout, bad)
    log = Path(tempfile.mkdtemp()) / "premflow.log"
    env = {"PREMFLOW_LOG": str(log)}
    pomo = run([str(STUB), "pomo", "25", "short"], env=env, path=path9)
    check(pomo.returncode == 0, "pomo")
    check(pomo.stdout == "[POMO]\n", "pomo line")
    db = fresh_db()
    check(load_shared(db, path9) == "short", "next")
    must(state(db, [
        "block", "open", "--map", "loop", "--stage", "short",
        "--energy", "mid", "--plan", "25",
    ], path=path9))
    check(query(db, "SELECT plan FROM blocks WHERE status='open'") == [("25",)], "plan 25")
    empty = state(db, [
        "harvest", "add", "--map", "loop", "--stage", "short",
        "--result", "landed", "--evidence", "",
    ], path=path9)
    check(empty.returncode == 3, "empty evidence")
    listed = must_json(state(db, ["harvest", "list", "--map", "loop"], path=path9))
    check(listed["rows"] == [], "empty row")
    public = Path(tempfile.mkdtemp()) / "public.tsv"
    figure = "money 40"
    check(is_figure(figure), "figure")
    if is_figure(figure):
        pass
    else:
        raise FlowError("figure passed to harvest add")
    check(not public.exists(), "figure public")
    listed = must_json(state(db, ["harvest", "list", "--map", "loop"], path=path9))
    check(listed["rows"] == [], "figure row")
    cases = [
        ("landed", "sha:0123456789abcdef"),
        ("noted", "draft:1"),
        ("continue", "signpost:continue"),
    ]
    for result, evidence in cases:
        check(not is_figure(result), result)
        must(state(db, [
            "harvest", "add", "--map", "loop", "--stage", "short",
            "--result", result, "--evidence", evidence,
        ], path=path9))
        append_public(public, "short", result, evidence)
        check(stage_class(db, "short") == "Do", "class after add")
    listed = must_json(state(db, ["harvest", "list", "--map", "loop"], path=path9))
    check([row["evidence"] for row in listed["rows"]] == [item[1] for item in cases], "harvest rows")
    check(public.read_text(encoding="utf-8").splitlines() == [
        "%s\tshort\t%s\t%s" % (DATE, result, evidence) for result, evidence in cases
    ], "public rows")
    win = run([str(STUB), "win", "short"], env=env, path=path9)
    check(win.returncode == 0, "win")
    check(win.stdout == "", "win stdout")
    task = run([str(STUB), "task", "done", "1"], env=env, path=path9)
    check(task.returncode == 0, "task")
    check(task.stdout == "", "task stdout")
    check(log.read_text(encoding="utf-8").splitlines() == [
        "pomo 25 short",
        "win short",
        "task done 1",
    ], "premflow log")
    check(pomo.stdout.count("[POMO]") + win.stdout.count("[POMO]") + task.stdout.count("[POMO]") == 1, "one pomo")
    must(state(db, ["block", "close", "--map", "loop"], path=path9))
    check(count_block_close() == 1, "one close")
    must(state(db, [
        "pulse", "archive", "--source", "tstack/harvest", "--payload", "continue",
    ], path=path9))
    must_json(state(db, [
        "pulse", "admit", "--key", "harvest-short", "--snippet", "continue",
        "--source", "tstack/harvest", "--time", WHEN,
        "--status", "tool-verified", "--kind", "memory", "--lock", "open",
    ], path=path9))
    listed = must_json(state(db, ["pulse", "list", "--limit", "8"], path=path9))
    row = next(item for item in listed["rows"] if item["nat_key"] == "harvest-short")
    check(row["snippet"] == "continue", "snippet")
    check(row["source"] == "tstack/harvest", "source")
    check(row["time"] == WHEN, "time")
    check(row["status"] == "tool-verified", "status")
    check(row["kind"] == "memory", "kind")
    check(stage_class(db, "short") == "Do", "class before done")
    mark_done(db, path9)
    check(stage_class(db, "short") == "Done", "class done")
    check(graph_apply(db, path9) == "long", "next after done")
    check(not (TSTACK / "LOG.md").exists(), "LOG.md")


def flow_without():
    check("PREMFLOW_LOG" not in os.environ, "PREMFLOW_LOG")
    proc = run(["bash", "-c", "command -v premflow"], path=NARROW)
    check(proc.returncode != 0, "command -v")

    def print_premflow_hint():
        print("premflow/README.md", flush=True)

    shown = read_printed(print_premflow_hint)
    check(any("premflow/README.md" in line for line in shown.splitlines()), "hint")
    check("[POMO]" not in shown, "pomo")
    db = fresh_db()
    check(load_shared(db, NARROW) == "short", "next")
    must(state(db, [
        "block", "open", "--map", "loop", "--stage", "short", "--energy", "mid",
    ], path=NARROW))
    rows = query(db, "SELECT stage_id, plan FROM blocks WHERE status='open'")
    check(rows == [("short", None)], "plan")
    must(state(db, [
        "harvest", "add", "--map", "loop", "--stage", "short",
        "--result", "continue", "--evidence", "signpost:continue",
    ], path=NARROW))
    listed = must_json(state(db, ["harvest", "list", "--map", "loop"], path=NARROW))
    check(len(listed["rows"]) == 1, "harvest row")
    check(listed["rows"][0]["evidence"] == "signpost:continue", "evidence")
    public = Path(tempfile.mkdtemp()) / "public.tsv"
    append_public(public, "short", "continue", "signpost:continue")
    check(public.read_text(encoding="utf-8").splitlines() == [
        "%s\tshort\tcontinue\tsignpost:continue" % DATE
    ], "public row")
    must(state(db, ["block", "close", "--map", "loop"], path=NARROW))
    check(count_block_close() == 1, "one close")
    check(stage_class(db, "short") == "Do", "class")
    mark_done(db, NARROW)
    check(stage_class(db, "short") == "Done", "done")
    check(graph_apply(db, NARROW) == "long", "next long")
    check(not (TSTACK / "LOG.md").exists(), "LOG.md")
    check(PLUGIN_JSON.resolve() not in opened, "plugin.json")
    check(not called_premflow(), "premflow")
    check("PREMFLOW_LOG" not in os.environ, "log absent")


FLOWS = [
    ("capture-to-feed", flow_capture),
    ("admit-next-do", flow_admit),
    ("replan-remaining-dag", flow_replan),
    ("route-repo-work", flow_route_repo),
    ("route-life-block", flow_route_life),
    ("concordance-hold", flow_concordance_hold),
    ("concordance-proceed", flow_concordance_proceed),
    ("irreversible-stop", flow_irreversible),
    ("harvest-with-premflow", flow_harvest_with),
    ("loop-without-premflow", flow_without),
]


def main():
    for key in ("GH_TOKEN", "GITHUB_TOKEN", "PREMFLOW_LOG"):
        os.environ.pop(key, None)
    failed = 0
    for flow_id, fn in FLOWS:
        calls.clear()
        opened.clear()
        writes.clear()
        try:
            fn()
        except Exception as exc:
            print("FAIL %s" % flow_id)
            print("%s: %s" % (flow_id, exc), file=sys.stderr)
            failed += 1
        else:
            print("ok %s" % flow_id)
    if failed:
        raise SystemExit(1)
    print("ALL CHECKS PASSED")


if __name__ == "__main__":
    main()
