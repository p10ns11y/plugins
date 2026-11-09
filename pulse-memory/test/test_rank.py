#!/usr/bin/env python3
"""KDI rank tests. Temp DBs only."""

import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from pulse_common import HIT_SOURCE, admit, init_schema, retrieve  # noqa: E402
from pulse_rank import rank, weekly  # noqa: E402

NOW = datetime(2026, 3, 1, tzinfo=timezone.utc)
OLD = (NOW - timedelta(days=30)).isoformat()


def fresh():
    tmp = tempfile.TemporaryDirectory()
    path = Path(tmp.name) / "pulse.sqlite"
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    init_schema(conn)
    return tmp, path, conn


def hit(conn, key, when):
    conn.execute(
        "INSERT INTO archive_events(ts, source, payload, correlation_id) VALUES (?,?,?,?)",
        (when.isoformat(), HIT_SOURCE, json.dumps({"keys": [key], "mode": "key"}), key),
    )
    conn.commit()


def tiers(report):
    return {t["key"]: t["tier"] for t in report["traces"]}


class RetrieveLogsHits(unittest.TestCase):
    def test_hit_logged_with_keys_only(self):
        tmp, _, conn = fresh()
        admit(conn, "a/one", "Secret-free pulse.", source="test")
        retrieve(conn, key="a/one")
        rows = conn.execute("SELECT payload FROM archive_events WHERE source=?", (HIT_SOURCE,)).fetchall()
        self.assertEqual(len(rows), 1)
        self.assertEqual(json.loads(rows[0][0]), {"keys": ["a/one"], "mode": "key"})
        retrieve(conn, key="missing/key")
        retrieve(conn, key="a/one", log=False)
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM archive_events WHERE source=?", (HIT_SOURCE,)).fetchone()[0], 1)
        conn.close()
        tmp.cleanup()

    def test_env_turns_logging_off(self):
        tmp, _, conn = fresh()
        admit(conn, "a/one", "Pulse.", source="test")
        os.environ["PULSE_RETRIEVE_LOG"] = "0"
        try:
            retrieve(conn, key="a/one")
        finally:
            del os.environ["PULSE_RETRIEVE_LOG"]
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM archive_events").fetchone()[0], 0)
        conn.close()
        tmp.cleanup()


class Rank(unittest.TestCase):
    def setUp(self):
        self.tmp, self.path, self.conn = fresh()
        c = self.conn
        admit(c, "t/used", "Used pulse.", source="test", time=OLD)
        admit(c, "t/locked", "Locked pulse.", source="test", lock="locked", time=OLD)
        admit(c, "t/said-twice", "Twice.", source="test", time=OLD)
        admit(c, "t/said-twice", "Twice.", source="test", time=OLD)
        admit(c, "t/idle", "Never read.", source="test", time=OLD)
        admit(c, "t/old", "Old rule.", source="test", time=OLD)
        admit(c, "t/new", "New rule.", source="test", time=OLD, supersede="t/old")
        admit(c, "t/young", "Fresh.", source="test", time=(NOW - timedelta(days=2)).isoformat())
        hit(c, "t/used", NOW - timedelta(days=20))
        hit(c, "t/used", NOW - timedelta(days=1))

    def tearDown(self):
        self.conn.close()
        self.tmp.cleanup()

    def test_tiers_from_recorded_signals(self):
        report = rank(self.conn, NOW, days=7, min_age=14)
        self.assertTrue(report["hit_log"]["covers_window"])
        got = tiers(report)
        self.assertEqual(got["t/used"], "earned")
        self.assertEqual(got["t/locked"], "earned")
        self.assertEqual(got["t/said-twice"], "earned")
        self.assertEqual(got["t/new"], "earned")
        self.assertEqual(got["t/old"], "stale")
        self.assertEqual(got["t/idle"], "idle")
        self.assertEqual(got["t/young"], "young")
        self.assertEqual([p["key"] for p in report["prune"]], ["t/old", "t/idle"])
        self.assertEqual(report["top"][0]["key"], "t/locked")

    def test_dry_run_changes_nothing(self):
        before = self.conn.execute("SELECT COUNT(*), SUM(seen_count) FROM memory_traces").fetchone()
        events = self.conn.execute("SELECT COUNT(*) FROM archive_events").fetchone()[0]
        env = dict(os.environ, PULSE_MEMORY_DB=str(self.path))
        out = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "pulse_rank.py"), "--as-of", NOW.isoformat()],
            env=env, text=True, capture_output=True,
        )
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertTrue(json.loads(out.stdout)["dry_run"])
        conn = sqlite3.connect(self.path)
        self.assertEqual(conn.execute("SELECT COUNT(*), SUM(seen_count) FROM memory_traces").fetchone(), tuple(before))
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM archive_events").fetchone()[0], events)
        conn.close()

    def test_record_appends_only(self):
        env = dict(os.environ, PULSE_MEMORY_DB=str(self.path))
        out = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "pulse_rank.py"), "--as-of", NOW.isoformat(), "--record"],
            env=env, text=True, capture_output=True,
        )
        self.assertEqual(out.returncode, 0, out.stderr)
        conn = sqlite3.connect(self.path)
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM memory_traces").fetchone()[0], 7)
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM archive_events WHERE source='pulse/rank'").fetchone()[0], 1)
        conn.close()

    def test_uncovered_log_holds_idle(self):
        self.conn.execute("DELETE FROM archive_events")
        self.conn.commit()
        hit(self.conn, "t/used", NOW - timedelta(days=1))
        report = rank(self.conn, NOW, days=7, min_age=14)
        self.assertFalse(report["hit_log"]["covers_window"])
        self.assertEqual(tiers(report)["t/idle"], "unproven")
        self.assertEqual([p["key"] for p in report["prune"]], ["t/old"])

    def test_hash_mismatch_is_repair_not_prune(self):
        self.conn.execute("UPDATE memory_traces SET snippet='tampered' WHERE nat_key='t/idle'")
        self.conn.commit()
        report = rank(self.conn, NOW, days=7, min_age=14)
        self.assertEqual(report["repair"], ["t/idle"])
        self.assertNotIn("t/idle", [p["key"] for p in report["prune"]])

    def test_cap_keeps_it_sparse(self):
        report = rank(self.conn, NOW, days=7, min_age=14, cap=1)
        self.assertEqual(len(report["prune"]), 1)
        self.assertEqual(report["prune_more"], 1)

    def test_weekly_markdown(self):
        text = weekly(rank(self.conn, NOW, days=7, min_age=14))
        self.assertIn("# Pulse KDI week to 2026-03-01", text)
        self.assertIn("nothing deleted", text)
        self.assertIn("`t/old` stale", text)


if __name__ == "__main__":
    unittest.main(verbosity=2)
