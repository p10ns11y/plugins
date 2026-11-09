#!/usr/bin/env python3
"""Admit one memory trace, with a content hash and a prefetch key.

  pulse_admit.py NAT_KEY SNIPPET [source] [status] [kind] [lock]
  pulse_admit.py --supersede OLD_KEY NAT_KEY SNIPPET [source] [status] [kind] [lock]
  echo '{"nat_key":"...","snippet":"..."}' | pulse_admit.py --json
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pulse_common import (
    AdmitRejected,
    admit,
    connect,
    reject_and_maybe_archive,
)


def run_admit(obj, source_explicit=True, supersede=None):
    conn = connect()
    try:
        return admit(
            conn,
            obj["nat_key"],
            obj["snippet"],
            obj.get("source", "steward"),
            obj.get("status", "user-stated"),
            obj.get("kind", "memory"),
            obj.get("lock", "open"),
            obj.get("time"),
            supersede=supersede or obj.get("supersede") or obj.get("supersedes"),
            source_explicit=source_explicit,
            topic=obj.get("topic"),
        )
    except AdmitRejected as exc:
        reject_and_maybe_archive(
            conn,
            exc.reason,
            obj.get("source", "unknown"),
            obj.get("nat_key"),
            obj.get("snippet"),
            exc.archive,
        )
        print(f"rejected:{exc.reason}")
        sys.exit(3)
    finally:
        conn.close()


def from_json(raw, supersede=None):
    if not raw.strip():
        raise SystemExit("empty stdin for --json")
    obj = json.loads(raw)
    source_explicit = "source" in obj
    print(run_admit(obj, source_explicit=source_explicit, supersede=supersede))


def main():
    args = sys.argv[1:]
    supersede = None
    if args and args[0] == "--supersede":
        if len(args) < 2:
            print("usage: pulse_admit.py --supersede OLD_KEY ...", file=sys.stderr)
            sys.exit(2)
        supersede = args[1]
        args = args[2:]
    if args and args[0] in ("--json", "-j"):
        from_json(sys.stdin.read(), supersede=supersede)
        return
    if not args and not sys.stdin.isatty():
        raw = sys.stdin.read()
        if raw.strip().startswith("{"):
            from_json(raw, supersede=supersede)
            return
    if len(args) < 2:
        print(
            "usage: pulse_admit.py NAT_KEY SNIPPET [source] [status] [kind] [lock]\n"
            "       pulse_admit.py --supersede OLD_KEY NAT_KEY SNIPPET [...]\n"
            "       pulse_admit.py --json < trace.json",
            file=sys.stderr,
        )
        sys.exit(2)
    obj = {
        "nat_key": args[0],
        "snippet": args[1],
        "source": args[2] if len(args) > 2 else "steward",
        "status": args[3] if len(args) > 3 else "user-stated",
        "kind": args[4] if len(args) > 4 else "memory",
        "lock": args[5] if len(args) > 5 else "open",
    }
    source_explicit = len(args) > 2
    print(run_admit(obj, source_explicit=source_explicit, supersede=supersede))


if __name__ == "__main__":
    main()
