#!/usr/bin/env python3
"""Fill empty verify_hash and prefetch_key values. Idempotent. No deletes."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pulse_common import backfill, connect


def main():
    if "-h" in sys.argv or "--help" in sys.argv:
        print("usage: pulse_backfill.py")
        return
    conn = connect()
    try:
        result = backfill(conn)
        print(json.dumps(result, ensure_ascii=False))
        if result["before"] != result["after"]:
            sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
