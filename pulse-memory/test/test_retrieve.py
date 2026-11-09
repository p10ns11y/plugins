#!/usr/bin/env python3
"""Admit, retrieve, hash, prefetch, and backfill tests. Uses temp DBs only."""

import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from pulse_common import (  # noqa: E402
    AdmitRejected,
    MAX_RETRIEVE,
    admit,
    backfill,
    content_hash,
    hash_matches,
    init_schema,
    prefetch_key_for,
    retrieve,
    topic_of,
)


def fresh():
    tmp = tempfile.TemporaryDirectory()
    path = Path(tmp.name) / "pulse.sqlite"
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    init_schema(conn)
    return tmp, conn


class HashAndPrefetch(unittest.TestCase):
    def test_hash_is_deterministic_and_prefixed(self):
        first = content_hash("locked revision")
        second = content_hash("locked revision")
        other = content_hash("other revision")
        self.assertTrue(first.startswith("sha256:"))
        self.assertEqual(first, second)
        self.assertNotEqual(first, other)
        self.assertTrue(hash_matches("locked revision", first))
        self.assertFalse(hash_matches("locked revision", other))
        self.assertFalse(hash_matches("locked revision", None))
        self.assertFalse(hash_matches("locked revision", ""))

    def test_prefetch_key_from_nat_key_kind_and_topic(self):
        self.assertEqual(topic_of("apply/example/constraints"), "apply/example")
        self.assertEqual(
            prefetch_key_for("apply/example/constraints", "fact"),
            "apply/example/fact",
        )
        self.assertEqual(prefetch_key_for("hunt/ledger/demo", "memory"), "hunt/ledger/memory")
        self.assertEqual(prefetch_key_for("civic:item", "fact"), "civic/fact")
        self.assertEqual(prefetch_key_for("solo", "memory"), "solo/memory")
        self.assertEqual(
            prefetch_key_for("apply/example/constraints#fork", "fact"),
            "apply/example/fact",
        )
        self.assertEqual(
            prefetch_key_for("apply/example/constraints", "fact", topic="apply/example"),
            "apply/example/fact",
        )


class AdmitAndRetrieve(unittest.TestCase):
    def setUp(self):
        self.tmp, self.conn = fresh()

    def tearDown(self):
        self.conn.close()
        self.tmp.cleanup()

    def test_admit_fills_hash_and_prefetch(self):
        status = admit(
            self.conn,
            "apply/example/constraints",
            "Keep the apply example under the published cap.",
            source="test",
            status="user-stated",
            kind="fact",
            lock="locked",
        )
        self.assertEqual(status, "inserted")
        row = self.conn.execute(
            "SELECT * FROM memory_traces WHERE nat_key=?",
            ("apply/example/constraints",),
        ).fetchone()
        self.assertEqual(row["verify_hash"], content_hash(row["snippet"]))
        self.assertEqual(row["prefetch_key"], "apply/example/fact")

    def test_retrieve_exact_key_returns_one_pulse(self):
        admit(
            self.conn,
            "apply/example/constraints",
            "Keep the apply example under the published cap.",
            source="test",
            status="tool-verified",
            kind="fact",
            lock="locked",
        )
        admit(
            self.conn,
            "apply/example/projects",
            "Show three public projects on the apply example.",
            source="test",
            status="user-stated",
            kind="memory",
        )
        result = retrieve(self.conn, key="apply/example/constraints")
        self.assertTrue(result["ok"])
        self.assertEqual(len(result["pulses"]), 1)
        pulse = result["pulses"][0]
        self.assertEqual(pulse["key"], "apply/example/constraints")
        self.assertEqual(pulse["verify"], content_hash(pulse["snippet"]))
        self.assertEqual(pulse["prefetch"], "apply/example/fact")
        self.assertEqual(pulse["trust"], "locked")
        self.assertLess(result["stats"]["returned_chars"], result["stats"]["corpus_chars"])
        self.assertGreater(result["stats"]["avoided_chars"], 0)

    def test_retrieve_prefetch_returns_neighborhood(self):
        admit(self.conn, "apply/example/one", "First example pulse.", source="test", kind="memory")
        admit(self.conn, "apply/example/two", "Second example pulse.", source="test", kind="memory")
        admit(self.conn, "other/topic/three", "Unrelated pulse.", source="test", kind="memory")
        result = retrieve(self.conn, prefetch_key="apply/example/memory", limit=3)
        self.assertTrue(result["ok"])
        keys = {pulse["key"] for pulse in result["pulses"]}
        self.assertEqual(keys, {"apply/example/one", "apply/example/two"})
        self.assertNotIn("other/topic/three", keys)

    def test_hash_mismatch_is_unknown(self):
        admit(self.conn, "apply/example/constraints", "Original pulse.", source="test")
        self.conn.execute(
            "UPDATE memory_traces SET snippet=? WHERE nat_key=?",
            ("tampered pulse", "apply/example/constraints"),
        )
        self.conn.commit()
        result = retrieve(self.conn, key="apply/example/constraints")
        self.assertFalse(result["ok"])
        self.assertEqual(result["status"], "unknown")
        self.assertEqual(result["reason"], "hash_mismatch")
        self.assertEqual(result["pulses"], [])

    def test_stale_row_is_unknown(self):
        admit(self.conn, "apply/example/old", "Old constraint.", source="test")
        admit(
            self.conn,
            "apply/example/new",
            "New constraint.",
            source="test",
            supersede="apply/example/old",
        )
        result = retrieve(self.conn, key="apply/example/old")
        self.assertFalse(result["ok"])
        self.assertEqual(result["reason"], "stale")
        fresh = retrieve(self.conn, key="apply/example/new")
        self.assertTrue(fresh["ok"])
        self.assertEqual(fresh["pulses"][0]["key"], "apply/example/new")

    def test_empty_or_star_query_does_not_dump(self):
        for i in range(12):
            admit(self.conn, f"apply/example/{i}", f"Example pulse {i}.", source="test")
        empty = retrieve(self.conn, query="")
        star = retrieve(self.conn, query="*")
        self.assertFalse(empty["ok"])
        self.assertEqual(empty["reason"], "empty_query")
        self.assertEqual(empty["pulses"], [])
        self.assertFalse(star["ok"])
        self.assertEqual(star["pulses"], [])
        capped = retrieve(self.conn, query="example", limit=99)
        self.assertLessEqual(len(capped["pulses"]), MAX_RETRIEVE)
        self.assertLessEqual(capped["stats"]["returned"], MAX_RETRIEVE)

    def test_prefers_locked_over_belief(self):
        admit(
            self.conn,
            "apply/example/belief",
            "A guessed constraint.",
            source="test",
            status="user-stated",
            kind="memory",
            lock="open",
        )
        admit(
            self.conn,
            "apply/example/locked",
            "The locked constraint.",
            source="test",
            status="tool-verified",
            kind="memory",
            lock="locked",
        )
        result = retrieve(self.conn, query="apply/example", limit=3)
        self.assertTrue(result["ok"])
        keys = [pulse["key"] for pulse in result["pulses"]]
        self.assertIn("apply/example/locked", keys)
        self.assertNotIn("apply/example/belief", keys)
        self.assertEqual(result["pulses"][0]["trust"], "locked")

    def test_missing_key_is_unknown(self):
        result = retrieve(self.conn, key="apply/example/missing")
        self.assertFalse(result["ok"])
        self.assertEqual(result["reason"], "not_in_the_evidence")
        self.assertEqual(result["status"], "unknown")


class AdmitRejects(unittest.TestCase):
    def setUp(self):
        self.tmp, self.conn = fresh()

    def tearDown(self):
        self.conn.close()
        self.tmp.cleanup()

    def test_empty_snippet_is_archived(self):
        with self.assertRaises(AdmitRejected) as caught:
            admit(self.conn, "apply/example/empty", "   ", source="test")
        self.assertTrue(caught.exception.archive)

    def test_inferred_needs_explicit_source(self):
        with self.assertRaises(AdmitRejected):
            admit(
                self.conn,
                "apply/example/guess",
                "A guess.",
                source="steward",
                status="inferred",
                source_explicit=False,
            )

    def test_inferred_cannot_lock(self):
        with self.assertRaises(AdmitRejected):
            admit(
                self.conn,
                "apply/example/guess",
                "A guess.",
                source="test",
                status="inferred",
                lock="locked",
                source_explicit=True,
            )

    def test_too_long_snippet_is_rejected(self):
        with self.assertRaises(AdmitRejected) as caught:
            admit(self.conn, "apply/example/long", "x" * 801, source="test")
        self.assertEqual(caught.exception.reason, "snippet too long for a pulse")

    def test_locked_conflict_is_not_averaged(self):
        admit(
            self.conn,
            "apply/example/cap",
            "First locked text.",
            source="test",
            lock="locked",
        )
        result = admit(
            self.conn,
            "apply/example/cap",
            "Second disagreeing text.",
            source="test",
            lock="open",
        )
        self.assertTrue(result.startswith("conflict->"))
        count = self.conn.execute("SELECT COUNT(*) FROM conflicts").fetchone()[0]
        self.assertEqual(count, 1)
        original = self.conn.execute(
            "SELECT snippet FROM memory_traces WHERE nat_key=?",
            ("apply/example/cap",),
        ).fetchone()[0]
        self.assertEqual(original, "First locked text.")


class Backfill(unittest.TestCase):
    def test_backfill_is_idempotent_and_keeps_row_count(self):
        tmp, conn = fresh()
        try:
            admit(conn, "apply/example/one", "One.", source="test")
            admit(conn, "apply/example/two", "Two.", source="test")
            conn.execute(
                "UPDATE memory_traces SET verify_hash=NULL, prefetch_key=NULL"
            )
            conn.commit()
            first = backfill(conn)
            self.assertEqual(first["before"], 2)
            self.assertEqual(first["after"], 2)
            self.assertEqual(first["filled_hash"], 2)
            self.assertEqual(first["filled_prefetch"], 2)
            self.assertEqual(first["empty_hash"], 0)
            self.assertEqual(first["empty_prefetch"], 0)
            row = conn.execute(
                "SELECT verify_hash, prefetch_key, snippet FROM memory_traces WHERE nat_key=?",
                ("apply/example/one",),
            ).fetchone()
            self.assertEqual(row["verify_hash"], content_hash(row["snippet"]))
            self.assertEqual(row["prefetch_key"], "apply/example/memory")
            second = backfill(conn)
            self.assertEqual(second["before"], 2)
            self.assertEqual(second["after"], 2)
            self.assertEqual(second["filled_hash"], 0)
            self.assertEqual(second["filled_prefetch"], 0)
        finally:
            conn.close()
            tmp.cleanup()


class CliSmoke(unittest.TestCase):
    def test_cli_admit_retrieve_roundtrip(self):
        import subprocess

        tmp = tempfile.TemporaryDirectory()
        db = Path(tmp.name) / "pulse.sqlite"
        conn = sqlite3.connect(db)
        init_schema(conn)
        conn.close()
        env = os.environ.copy()
        env["PULSE_MEMORY_DB"] = str(db)
        admit_py = ROOT / "scripts" / "pulse_admit.py"
        retrieve_py = ROOT / "scripts" / "pulse_retrieve.py"
        backfill_py = ROOT / "scripts" / "pulse_backfill.py"
        inserted = subprocess.check_output(
            [sys.executable, str(admit_py), "apply/example/cli", "CLI pulse.", "test", "user-stated", "memory", "open"],
            env=env,
            text=True,
        ).strip()
        self.assertEqual(inserted, "inserted")
        payload = json.loads(
            subprocess.check_output(
                [sys.executable, str(retrieve_py), "--key", "apply/example/cli"],
                env=env,
                text=True,
            )
        )
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["pulses"][0]["key"], "apply/example/cli")
        filled = json.loads(
            subprocess.check_output([sys.executable, str(backfill_py)], env=env, text=True)
        )
        self.assertEqual(filled["before"], filled["after"])
        tmp.cleanup()


class OneAdmitPath(unittest.TestCase):
    def run_py(self, script, *args, env):
        return subprocess.run(
            [sys.executable, str(ROOT / "scripts" / script), *args],
            env=env, text=True, capture_output=True,
        )

    def test_init_db_creates_private_store(self):
        tmp = tempfile.TemporaryDirectory()
        db = Path(tmp.name) / "nested" / "pulse.sqlite"
        env = os.environ.copy()
        env["PULSE_MEMORY_DB"] = str(db)
        first = self.run_py("pulse_init_db.py", env=env)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(json.loads(first.stdout)["db"], "created")
        self.assertEqual(db.stat().st_mode & 0o777, 0o600)
        again = self.run_py("pulse_init_db.py", env=env)
        self.assertEqual(json.loads(again.stdout)["db"], "ready")
        admitted = self.run_py("pulse_admit.py", "a/b", "kept", "test", env=env)
        self.assertEqual(admitted.stdout.strip(), "inserted")
        tmp.cleanup()

    def test_wide_store_narrowed_to_0600_data_kept(self):
        tmp = tempfile.TemporaryDirectory()
        db = Path(tmp.name) / "pulse.sqlite"
        env = os.environ.copy()
        env["PULSE_MEMORY_DB"] = str(db)
        self.assertEqual(self.run_py("pulse_init_db.py", env=env).returncode, 0)
        self.run_py("pulse_admit.py", "a/b", "kept", "test", env=env)
        conn = sqlite3.connect(db)
        before = conn.execute(
            "SELECT nat_key, snippet, verify_hash FROM memory_traces").fetchall()
        conn.close()
        sidecars = [Path(f"{db}-wal"), Path(f"{db}-shm")]
        for file in [db, *sidecars]:
            file.touch()
            os.chmod(file, 0o644)
        admitted = self.run_py("pulse_admit.py", "a/c", "next", "test", env=env)
        self.assertEqual(admitted.stdout.strip(), "inserted", admitted.stderr)
        for file in [db, *sidecars]:
            if file.exists():
                self.assertEqual(file.stat().st_mode & 0o777, 0o600, file.name)
        os.chmod(db, 0o664)
        ready = self.run_py("pulse_init_db.py", env=env)
        self.assertEqual(json.loads(ready.stdout)["db"], "ready")
        self.assertEqual(db.stat().st_mode & 0o777, 0o600)
        conn = sqlite3.connect(db)
        after = conn.execute(
            "SELECT nat_key, snippet, verify_hash FROM memory_traces WHERE nat_key='a/b'"
        ).fetchall()
        self.assertEqual(before, after)
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM memory_traces").fetchone()[0], 2)
        conn.close()
        tmp.cleanup()

    def test_secure_store_never_widens(self):
        from pulse_common import secure_store
        tmp = tempfile.TemporaryDirectory()
        db = Path(tmp.name) / "pulse.sqlite"
        db.touch()
        os.chmod(db, 0o400)
        self.assertEqual(secure_store(db), [])
        self.assertEqual(db.stat().st_mode & 0o777, 0o400)
        os.chmod(db, 0o755)
        wal = Path(f"{db}-wal")
        wal.touch()
        os.chmod(wal, 0o644)
        self.assertEqual(secure_store(db), ["pulse.sqlite", "pulse.sqlite-wal"])
        self.assertEqual(db.stat().st_mode & 0o777, 0o600)
        self.assertEqual(wal.stat().st_mode & 0o777, 0o600)
        tmp.cleanup()

    def test_locked_disagreement_forks_without_averaging(self):
        tmp, conn = fresh()
        admit(conn, "trace", "alpha", source="test", lock="locked")
        self.assertEqual(admit(conn, "trace", "beta", source="test", lock="locked"), "conflict->trace-2")
        self.assertEqual(admit(conn, "trace", "gamma", source="test", lock="locked"), "conflict->trace-3")
        row = conn.execute("SELECT snippet FROM memory_traces WHERE nat_key='trace'").fetchone()
        self.assertEqual(row["snippet"], "alpha")
        res = {r[0] for r in conn.execute("SELECT resolution FROM conflicts")}
        self.assertEqual(res, {"not in the evidence"})
        self.assertEqual(admit(conn, "trace", "alpha", source="test", lock="locked"), "upserted")
        conn.close()
        tmp.cleanup()

    def test_bad_key_rejected(self):
        tmp, conn = fresh()
        for key in ("", "a@b", "k" * 201):
            with self.assertRaises(AdmitRejected):
                admit(conn, key, "kept", source="test")
        conn.close()
        tmp.cleanup()

    def test_tstack_and_cli_write_the_same_row(self):
        state = ROOT.parent / "tstack" / "scripts" / "tstack-state"
        if not state.exists():
            self.skipTest("tstack not beside pulse-memory")
        rows = []
        for via in ("cli", "tstack"):
            tmp = tempfile.TemporaryDirectory()
            db = Path(tmp.name) / "pulse.sqlite"
            env = os.environ.copy()
            env.pop("TSTACK_STATE_DB", None)
            env["PULSE_MEMORY_DB"] = str(db)
            self.run_py("pulse_init_db.py", env=env)
            when = "2026-01-01T00:00:00Z"
            for snippet in ("one", "two"):
                if via == "cli":
                    obj = {"nat_key": "loop/turn", "snippet": snippet, "source": "test",
                           "status": "tool-verified", "kind": "memory", "lock": "locked", "time": when}
                    out = subprocess.run(
                        [sys.executable, str(ROOT / "scripts" / "pulse_admit.py"), "--json"],
                        input=json.dumps(obj), env=env, text=True, capture_output=True,
                    )
                else:
                    out = subprocess.run(
                        [sys.executable, str(state), "pulse", "admit", "--key", "loop/turn",
                         "--snippet", snippet, "--source", "test", "--time", when,
                         "--status", "tool-verified", "--kind", "memory", "--lock", "locked"],
                        env=env, text=True, capture_output=True,
                    )
                self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
            conn = sqlite3.connect(db)
            rows.append(conn.execute(
                """SELECT nat_key, snippet, status, kind, lock, verify_hash, prefetch_key, seen_count
                   FROM memory_traces ORDER BY nat_key"""
            ).fetchall() + conn.execute("SELECT subject, resolution FROM conflicts").fetchall())
            conn.close()
            tmp.cleanup()
        self.assertEqual(rows[0], rows[1])


if __name__ == "__main__":
    unittest.main(verbosity=2)
