#!/usr/bin/env python3
"""Rank lived traces by whether they earned their keep. Proposes a prune list. Deletes nothing.

  pulse_rank.py [--as-of ISO] [--days N] [--min-age N] [--max N] [--weekly] [--record]
"""

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pulse_common import HIT_SOURCE, archive_event, connect, hash_matches

RANK_SOURCE = "pulse/rank"
WEIGHTS = {"hit": 3, "restated": 1, "locked": 4, "supersedes": 2, "verified": 1}


def parse_time(raw):
    if not raw or raw == "unknown":
        return None
    try:
        t = datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
    except ValueError:
        return None
    return t if t.tzinfo else t.replace(tzinfo=timezone.utc)


def hits_by_key(conn, start, end):
    hits, first = {}, None
    rows = conn.execute(
        "SELECT ts, payload FROM archive_events WHERE source=? ORDER BY ts", (HIT_SOURCE,)
    )
    for row in rows:
        t = parse_time(row["ts"])
        if t is None:
            continue
        first = first or t
        if not (start <= t <= end):
            continue
        try:
            keys = json.loads(row["payload"]).get("keys", [])
        except (ValueError, AttributeError):
            continue
        for key in keys:
            hits[key] = hits.get(key, 0) + 1
    return hits, first


def rank(conn, as_of, days=7, min_age=14, cap=8):
    start = as_of - timedelta(days=days)
    hits, first_hit = hits_by_key(conn, start, as_of)
    covered = first_hit is not None and first_hit <= start
    winners = {}
    for row in conn.execute("SELECT superseded_by FROM memory_traces WHERE superseded_by IS NOT NULL AND superseded_by != ''"):
        winners[row[0]] = winners.get(row[0], 0) + 1
    conflicted = set()
    for row in conn.execute("SELECT left_id, right_id FROM conflicts"):
        conflicted.update(row)
    traces = []
    for row in conn.execute("SELECT * FROM memory_traces ORDER BY nat_key"):
        key = row["nat_key"]
        signals = {
            "hits": hits.get(key, 0),
            "restated": max(row["seen_count"] - 1, 0),
            "locked": row["lock"] == "locked",
            "supersedes": winners.get(key, 0),
            "verified": row["status"] == "tool-verified",
            "conflict": row["id"] in conflicted,
        }
        score = (
            WEIGHTS["hit"] * signals["hits"]
            + WEIGHTS["restated"] * signals["restated"]
            + WEIGHTS["locked"] * signals["locked"]
            + WEIGHTS["supersedes"] * signals["supersedes"]
            + WEIGHTS["verified"] * signals["verified"]
        )
        last = parse_time(row["last_seen"]) or parse_time(row["time"])
        age = (as_of - last).days if last else None
        if row["superseded_by"]:
            tier, why = "stale", f"superseded by {row['superseded_by']}"
        elif not hash_matches(row["snippet"], row["verify_hash"]):
            tier, why = "repair", "hash mismatch"
        elif signals["locked"] or signals["hits"] or signals["restated"] or signals["supersedes"]:
            tier, why = "earned", "used or locked"
        elif age is None or age < min_age:
            tier, why = "young", f"younger than {min_age}d"
        elif not covered:
            tier, why = "unproven", "hit log does not cover the window"
        else:
            tier, why = "idle", f"no hit in {days}d, said once, open"
        traces.append({"key": key, "kind": row["kind"], "score": score, "tier": tier, "why": why, "age_days": age, **signals})
    traces.sort(key=lambda t: (-t["score"], t["key"]))
    order = {"stale": 0, "idle": 1}
    pool = sorted((t for t in traces if t["tier"] in order), key=lambda t: (order[t["tier"]], t["score"], t["key"]))
    tiers = {}
    for t in traces:
        tiers[t["tier"]] = tiers.get(t["tier"], 0) + 1
    return {
        "ok": True,
        "dry_run": True,
        "as_of": as_of.isoformat(),
        "window_days": days,
        "hit_log": {"first": first_hit.isoformat() if first_hit else None, "covers_window": covered},
        "kdi": {"traces": len(traces), "tiers": tiers, "hits": sum(hits.values())},
        "prune": [{"key": t["key"], "tier": t["tier"], "why": t["why"]} for t in pool[:cap]],
        "prune_more": max(len(pool) - cap, 0),
        "repair": [t["key"] for t in traces if t["tier"] == "repair"],
        "top": [{"key": t["key"], "score": t["score"]} for t in traces if t["tier"] == "earned"][:cap],
        "traces": traces,
    }


def weekly(report):
    k = report["kdi"]
    lines = [
        f"# Pulse KDI week to {report['as_of'][:10]}",
        "",
        f"Traces {k['traces']} · retrieve hits {k['hits']} · window {report['window_days']}d · dry run",
        "",
        "| tier | n |",
        "|------|---|",
    ]
    lines += [f"| {tier} | {n} |" for tier, n in sorted(k["tiers"].items())]
    if not report["hit_log"]["covers_window"]:
        lines += ["", "Hit log is younger than the window. Idle is held as unproven."]
    lines += ["", "## Earned", ""]
    lines += [f"- `{t['key']}` {t['score']}" for t in report["top"]] or ["- none"]
    lines += ["", "## Prune proposals (nothing deleted)", ""]
    lines += [f"- `{p['key']}` {p['tier']}: {p['why']}" for p in report["prune"]] or ["- none"]
    if report["prune_more"]:
        lines.append(f"- and {report['prune_more']} more next week")
    if report["repair"]:
        lines += ["", "## Repair", ""] + [f"- `{key}` hash mismatch" for key in report["repair"]]
    return "\n".join(lines) + "\n"


def main():
    a = argparse.ArgumentParser(description="rank lived traces; propose a prune list; delete nothing")
    a.add_argument("--as-of")
    a.add_argument("--days", type=int, default=7)
    a.add_argument("--min-age", type=int, default=14)
    a.add_argument("--max", type=int, default=8)
    a.add_argument("--weekly", action="store_true", help="markdown report")
    a.add_argument("--record", action="store_true", help="append the proposal to archive_events")
    o = a.parse_args()
    as_of = parse_time(o.as_of) if o.as_of else datetime.now(timezone.utc)
    if as_of is None or o.days < 1 or o.min_age < 0 or o.max < 0:
        a.error("bad --as-of, --days, --min-age or --max")
    conn = connect()
    try:
        report = rank(conn, as_of, o.days, o.min_age, o.max)
        if o.record:
            archive_event(conn, RANK_SOURCE, {k: report[k] for k in ("as_of", "kdi", "prune", "repair")})
            conn.commit()
            report["dry_run"] = False
        print(weekly(report) if o.weekly else json.dumps(report, ensure_ascii=False))
    finally:
        conn.close()


if __name__ == "__main__":
    main()
