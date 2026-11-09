#!/usr/bin/env python3
"""Shared pulse admit, retrieve, and backfill helpers. Stdlib only."""

from __future__ import annotations

import hashlib
import hmac
import json
import os
import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

HASH_ALG = "sha256"
STATUSES = ("user-stated", "tool-verified", "inferred", "unknown")
KINDS = ("data", "context", "fact", "memory")
LOCKS = ("open", "locked")
STATUS_RANK = {
    "tool-verified": 40,
    "user-stated": 30,
    "inferred": 10,
    "unknown": 0,
}
MAX_SNIPPET_CHARS = 800
MAX_RETRIEVE = 8
DEFAULT_RETRIEVE = 1

SCHEMA = """
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS archive_events (
  id INTEGER PRIMARY KEY,
  ts TEXT NOT NULL,
  source TEXT NOT NULL,
  payload TEXT NOT NULL,
  correlation_id TEXT
);
CREATE TABLE IF NOT EXISTS memory_traces (
  id INTEGER PRIMARY KEY,
  nat_key TEXT NOT NULL UNIQUE,
  snippet TEXT NOT NULL,
  source TEXT NOT NULL,
  time TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN
    ('user-stated','tool-verified','inferred','unknown')),
  kind TEXT NOT NULL CHECK (kind IN
    ('data','context','fact','memory')),
  lock TEXT NOT NULL DEFAULT 'open' CHECK (lock IN ('open','locked')),
  verify_hash TEXT,
  prefetch_key TEXT,
  seen_count INTEGER NOT NULL DEFAULT 1,
  superseded_by TEXT,
  first_seen TEXT NOT NULL,
  last_seen TEXT NOT NULL
);
CREATE VIRTUAL TABLE IF NOT EXISTS memory_fts USING fts5(
  nat_key, snippet, source, content='memory_traces', content_rowid='id'
);
CREATE TABLE IF NOT EXISTS conflicts (
  id INTEGER PRIMARY KEY,
  subject TEXT NOT NULL,
  left_id INTEGER NOT NULL REFERENCES memory_traces(id),
  right_id INTEGER NOT NULL REFERENCES memory_traces(id),
  resolution TEXT NOT NULL,
  ts TEXT NOT NULL
);
"""


class AdmitRejected(Exception):
    def __init__(self, reason, archive=False):
        super().__init__(reason)
        self.reason = reason
        self.archive = archive


def now():
    return datetime.now(timezone.utc).isoformat()


def db_path() -> Path:
    env = os.environ.get("PULSE_MEMORY_DB")
    if env:
        return Path(env)
    return Path.home() / ".local/share/pulse-memory/pulse.sqlite"


STORE_MODE = 0o600
STORE_SIDECARS = ("", "-wal", "-shm", "-journal")


def secure_store(path) -> list:
    """Narrow the store and its SQLite sidecars to 0600 when wider. Data untouched."""
    narrowed = []
    for suffix in STORE_SIDECARS:
        file = Path(f"{path}{suffix}")
        try:
            mode = file.stat().st_mode & 0o777
        except FileNotFoundError:
            continue
        if mode & ~STORE_MODE:
            os.chmod(file, mode & STORE_MODE)
            narrowed.append(file.name)
    return narrowed


def connect():
    path = db_path()
    if not path.exists():
        raise SystemExit(f"missing db: {path} (run pulse_init_db.py)")
    secure_store(path)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_schema(conn):
    conn.executescript(SCHEMA)
    cur = conn.execute("SELECT 1 FROM schema_migrations WHERE version=1")
    if not cur.fetchone():
        conn.execute(
            "INSERT INTO schema_migrations(version, applied_at) VALUES (1, ?)",
            (now(),),
        )
    conn.commit()


def content_hash(snippet: str) -> str:
    digest = hashlib.sha256(snippet.encode("utf-8")).hexdigest()
    return f"{HASH_ALG}:{digest}"


def hash_matches(snippet: str, stored) -> bool:
    if not stored:
        return False
    expected = content_hash(snippet)
    if len(expected) != len(stored):
        return False
    return hmac.compare_digest(expected, stored)


def topic_of(nat_key: str) -> str:
    key = nat_key.split("#", 1)[0]
    if "/" in key:
        parts = [part for part in key.split("/") if part]
        if len(parts) >= 2:
            return "/".join(parts[:-1])
        return parts[0] if parts else key
    if ":" in key:
        return key.split(":", 1)[0]
    return key


def prefetch_key_for(nat_key: str, kind: str, topic: str | None = None) -> str:
    chosen = (topic or topic_of(nat_key)).strip()
    if not chosen:
        chosen = nat_key.split("#", 1)[0]
    return f"{chosen}/{kind}"


def archive_event(conn, source, payload, correlation_id=None):
    body = payload if isinstance(payload, str) else json.dumps(payload, ensure_ascii=False)
    conn.execute(
        """INSERT INTO archive_events (ts, source, payload, correlation_id)
           VALUES (?, ?, ?, ?)""",
        (now(), source, body, correlation_id),
    )


def sync_fts(conn):
    try:
        conn.execute("INSERT INTO memory_fts(memory_fts) VALUES('rebuild')")
    except sqlite3.OperationalError:
        pass


MAX_KEY_CHARS = 200


def check_admit(nat_key, snippet, source, status, kind, lock, source_explicit=True):
    key = "" if nat_key is None else str(nat_key).strip()
    if not key:
        raise AdmitRejected("empty nat_key")
    if len(key) > MAX_KEY_CHARS or "@" in key:
        raise AdmitRejected("bad nat_key")
    if status not in STATUSES:
        raise AdmitRejected("bad status")
    if kind not in KINDS:
        raise AdmitRejected("bad kind")
    if lock not in LOCKS:
        raise AdmitRejected("bad lock")
    text = "" if snippet is None else str(snippet)
    if not text.strip():
        raise AdmitRejected("empty snippet", archive=True)
    if len(text) > MAX_SNIPPET_CHARS:
        raise AdmitRejected("snippet too long for a pulse", archive=True)
    if status == "inferred" and not source_explicit:
        raise AdmitRejected("inferred write needs an explicit source", archive=True)
    if status == "inferred" and not str(source or "").strip():
        raise AdmitRejected("inferred write needs a source", archive=True)
    if status == "inferred" and lock == "locked":
        raise AdmitRejected("inferred write cannot be locked")
    return key, text


def fresh_key(conn, base):
    n = 2
    while True:
        candidate = f"{base}-{n}"
        if len(candidate) > MAX_KEY_CHARS:
            raise AdmitRejected("bad nat_key")
        taken = conn.execute(
            "SELECT 1 FROM memory_traces WHERE nat_key=?", (candidate,)
        ).fetchone()
        if taken is None:
            return candidate
        n += 1


def insert_trace(conn, key, text, source, t, status, kind, lock, topic=None):
    return conn.execute(
        """INSERT INTO memory_traces
        (nat_key, snippet, source, time, status, kind, lock,
         verify_hash, prefetch_key, seen_count, superseded_by,
         first_seen, last_seen)
        VALUES (?,?,?,?,?,?,?,?,?,1,NULL,?,?)""",
        (key, text, source, t, status, kind, lock,
         content_hash(text), prefetch_key_for(key, kind, topic), t, t),
    ).lastrowid


def admit_row(
    conn,
    nat_key,
    snippet,
    source="steward",
    status="user-stated",
    kind="memory",
    lock="open",
    time=None,
    supersede=None,
    source_explicit=True,
    topic=None,
):
    """One admit path for pulse_admit.py and tstack-state. Caller commits."""
    key, text = check_admit(nat_key, snippet, source, status, kind, lock, source_explicit)
    t = time or now()
    row = conn.execute(
        "SELECT id, snippet, lock, seen_count FROM memory_traces WHERE nat_key=?", (key,)
    ).fetchone()
    if row is None:
        new_id = insert_trace(conn, key, text, source, t, status, kind, lock, topic)
        _maybe_supersede(conn, key, supersede)
        if kind == "data":
            archive_event(
                conn,
                source,
                {"nat_key": key, "kind": kind, "reason": "data stays in archive"},
                key,
            )
        sync_fts(conn)
        return {"action": "inserted", "id": new_id, "nat_key": key, "seen_count": 1}
    if row["lock"] == "locked" and row["snippet"] != text:
        fork = fresh_key(conn, key)
        new_id = insert_trace(conn, fork, text, source, t, status, kind, lock, topic)
        conn.execute(
            "INSERT INTO conflicts(subject, left_id, right_id, resolution, ts) VALUES (?,?,?,?,?)",
            (key, row["id"], new_id, "not in the evidence", t),
        )
        sync_fts(conn)
        return {"action": "conflict", "id": new_id, "nat_key": fork, "seen_count": 1}
    conn.execute(
        """UPDATE memory_traces SET seen_count=seen_count+1, last_seen=?,
           snippet=CASE WHEN lock='open' THEN ? ELSE snippet END,
           time=CASE WHEN lock='open' THEN ? ELSE time END,
           status=CASE WHEN lock='open' THEN ? ELSE status END,
           source=CASE WHEN lock='open' THEN ? ELSE source END,
           verify_hash=CASE WHEN lock='open' THEN ? ELSE verify_hash END,
           prefetch_key=CASE WHEN lock='open' THEN ? ELSE prefetch_key END,
           kind=CASE WHEN lock='open' THEN ? ELSE kind END
           WHERE id=?""",
        (t, text, t, status, source, content_hash(text),
         prefetch_key_for(key, kind, topic), kind, row["id"]),
    )
    _maybe_supersede(conn, key, supersede)
    sync_fts(conn)
    return {
        "action": "upserted",
        "id": row["id"],
        "nat_key": key,
        "seen_count": row["seen_count"] + 1,
    }


def admit(conn, nat_key, snippet, *args, **kwargs):
    result = admit_row(conn, nat_key, snippet, *args, **kwargs)
    conn.commit()
    if result["action"] == "conflict":
        return f"conflict->{result['nat_key']}"
    return result["action"]


def _maybe_supersede(conn, winner, superseded):
    if not superseded or superseded == winner:
        return
    conn.execute(
        """UPDATE memory_traces SET superseded_by=?
           WHERE nat_key=? AND (superseded_by IS NULL OR superseded_by='')""",
        (winner, superseded),
    )


def reject_and_maybe_archive(conn, reason, source, nat_key, snippet, archive):
    if archive:
        archive_event(
            conn,
            source or "unknown",
            {
                "nat_key": nat_key,
                "reason": reason,
                "snippet_chars": len(snippet or ""),
            },
            nat_key,
        )
        conn.commit()


def like_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def is_stale(row) -> bool:
    return bool(row["superseded_by"])


def unknown_result(reason, corpus_chars, key=None):
    return {
        "ok": False,
        "status": "unknown",
        "reason": reason,
        "key": key,
        "pulses": [],
        "stats": {
            "returned": 0,
            "corpus_chars": corpus_chars,
            "returned_chars": 0,
            "avoided_chars": corpus_chars or 0,
        },
    }


def pulse_packet(row):
    return {
        "key": row["nat_key"],
        "verify": row["verify_hash"],
        "prefetch": row["prefetch_key"],
        "snippet": row["snippet"],
        "hint": {
            "source": row["source"],
            "time": row["time"],
            "status": row["status"],
            "kind": row["kind"],
            "lock": row["lock"],
        },
        "trust": "locked" if row["lock"] == "locked" else "belief",
    }


def score_row(row, wanted: str) -> int:
    key = row["nat_key"]
    points = 100
    if key == wanted:
        points = 1000
    elif row["prefetch_key"] == wanted:
        points = 500
    elif key.startswith(wanted.rstrip("/") + "/") or key.startswith(wanted):
        points = 300
    if row["lock"] == "locked":
        points += 50
    points += STATUS_RANK.get(row["status"], 0)
    points += {"memory": 8, "fact": 6, "context": 2, "data": 0}.get(row["kind"], 0)
    return points


def fts_or_like(conn, wanted: str):
    if wanted.strip() in {"*", "%", "match-all"}:
        return []
    tokens = re.findall(r"[A-Za-z0-9_./:-]+", wanted)
    if not tokens or tokens == ["*"]:
        return []
    try:
        match = " AND ".join('"' + token.replace('"', "") + '"' for token in tokens[:8])
        return list(
            conn.execute(
                """SELECT memory_traces.* FROM memory_traces
                   JOIN memory_fts ON memory_fts.rowid = memory_traces.id
                   WHERE memory_fts MATCH ?
                   LIMIT 16""",
                (match,),
            )
        )
    except sqlite3.OperationalError:
        pattern = "%" + like_escape(wanted) + "%"
        return list(
            conn.execute(
                """SELECT * FROM memory_traces
                   WHERE nat_key LIKE ? ESCAPE '\\' OR snippet LIKE ? ESCAPE '\\'
                   LIMIT 16""",
                (pattern, pattern),
            )
        )


def lookup_rows(conn, wanted: str, key=None, prefetch_key=None):
    if key:
        return list(conn.execute("SELECT * FROM memory_traces WHERE nat_key=?", (key,))), True
    if prefetch_key:
        return list(
            conn.execute("SELECT * FROM memory_traces WHERE prefetch_key=?", (prefetch_key,))
        ), False
    rows = list(conn.execute("SELECT * FROM memory_traces WHERE nat_key=?", (wanted,)))
    if rows:
        return rows, True
    rows = list(conn.execute("SELECT * FROM memory_traces WHERE prefetch_key=?", (wanted,)))
    if rows:
        return rows, False
    prefix = like_escape(wanted.rstrip("/"))
    rows = list(
        conn.execute(
            """SELECT * FROM memory_traces
               WHERE nat_key = ? OR nat_key LIKE ? ESCAPE '\\'
               LIMIT 16""",
            (wanted, prefix + "/%"),
        )
    )
    if rows:
        return rows, False
    return fts_or_like(conn, wanted), False


HIT_SOURCE = "pulse/retrieve"


def log_hits(conn, keys, mode):
    """Best effort: one archive row per retrieve that returned pulses. Keys only."""
    if not keys or os.environ.get("PULSE_RETRIEVE_LOG", "1") == "0":
        return
    own = not conn.in_transaction
    try:
        archive_event(conn, HIT_SOURCE, {"keys": keys, "mode": mode}, keys[0])
        if own:
            conn.commit()
    except sqlite3.Error:
        if own:
            conn.rollback()


def retrieve(conn, query="", limit=DEFAULT_RETRIEVE, key=None, prefetch_key=None, log=True):
    try:
        limit = int(limit)
    except (TypeError, ValueError):
        limit = DEFAULT_RETRIEVE
    if limit < 1:
        limit = 1
    if limit > MAX_RETRIEVE:
        limit = MAX_RETRIEVE
    corpus_chars = conn.execute(
        "SELECT COALESCE(SUM(length(snippet)), 0) FROM memory_traces"
    ).fetchone()[0]
    wanted = (key or prefetch_key or query or "").strip()
    if not wanted:
        return unknown_result("empty_query", corpus_chars)
    rows, exact = lookup_rows(conn, wanted, key=key, prefetch_key=prefetch_key)
    mismatches = []
    stale = []
    candidates = []
    for row in rows:
        if is_stale(row):
            stale.append(row)
            continue
        if not hash_matches(row["snippet"], row["verify_hash"]):
            mismatches.append(row)
            continue
        if row["kind"] == "data" and not (
            key or row["nat_key"] == (query or "").strip()
        ):
            continue
        candidates.append(row)
    if exact and not candidates:
        if mismatches:
            return unknown_result("hash_mismatch", corpus_chars, key=wanted)
        if stale:
            return unknown_result("stale", corpus_chars, key=wanted)
        return unknown_result("not_in_the_evidence", corpus_chars, key=wanted)
    if not candidates:
        if mismatches and not stale:
            return unknown_result("hash_mismatch", corpus_chars, key=wanted)
        if stale and not mismatches:
            return unknown_result("stale", corpus_chars, key=wanted)
        return unknown_result("not_in_the_evidence", corpus_chars, key=wanted)
    candidates.sort(
        key=lambda row: (
            score_row(row, wanted),
            row["lock"] == "locked",
            STATUS_RANK.get(row["status"], 0),
            row["last_seen"] or row["time"] or "",
        ),
        reverse=True,
    )
    locked = [row for row in candidates if row["lock"] == "locked"]
    if locked:
        locked_topics = {topic_of(row["nat_key"]) for row in locked}
        narrowed = []
        for row in candidates:
            if row["lock"] == "locked" or topic_of(row["nat_key"]) not in locked_topics:
                narrowed.append(row)
        candidates = narrowed
    chosen = candidates[:limit]
    pulses = [pulse_packet(row) for row in chosen]
    if log:
        mode = "key" if key else "prefetch" if prefetch_key else "query"
        log_hits(conn, [pulse["key"] for pulse in pulses], mode)
    returned_chars = sum(len(pulse["snippet"]) for pulse in pulses)
    return {
        "ok": True,
        "mode": "pulse",
        "pulses": pulses,
        "unknown": None,
        "stats": {
            "returned": len(pulses),
            "corpus_chars": corpus_chars,
            "returned_chars": returned_chars,
            "avoided_chars": max(int(corpus_chars) - returned_chars, 0),
        },
    }


def backfill(conn):
    rows = conn.execute(
        """SELECT id, nat_key, snippet, kind, verify_hash, prefetch_key
           FROM memory_traces"""
    ).fetchall()
    before = len(rows)
    filled_hash = 0
    filled_prefetch = 0
    for row in rows:
        sets = []
        args = []
        if not row["verify_hash"]:
            sets.append("verify_hash=?")
            args.append(content_hash(row["snippet"]))
            filled_hash += 1
        if not row["prefetch_key"]:
            sets.append("prefetch_key=?")
            args.append(prefetch_key_for(row["nat_key"], row["kind"]))
            filled_prefetch += 1
        if sets:
            args.append(row["id"])
            conn.execute(
                f"UPDATE memory_traces SET {', '.join(sets)} WHERE id=?",
                args,
            )
    sync_fts(conn)
    conn.commit()
    after = conn.execute("SELECT COUNT(*) FROM memory_traces").fetchone()[0]
    empty_hash = conn.execute(
        """SELECT COUNT(*) FROM memory_traces
           WHERE verify_hash IS NULL OR verify_hash=''"""
    ).fetchone()[0]
    empty_prefetch = conn.execute(
        """SELECT COUNT(*) FROM memory_traces
           WHERE prefetch_key IS NULL OR prefetch_key=''"""
    ).fetchone()[0]
    return {
        "before": before,
        "after": after,
        "filled_hash": filled_hash,
        "filled_prefetch": filled_prefetch,
        "empty_hash": empty_hash,
        "empty_prefetch": empty_prefetch,
    }
