#!/usr/bin/env python3
"""Create the pulse store at PULSE_MEMORY_DB, mode 0600. Idempotent. No deletes."""

import json
import os
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pulse_common import db_path, init_schema


def main():
    if "-h" in sys.argv or "--help" in sys.argv:
        print("usage: pulse_init_db.py")
        return
    os.umask(0o077)
    path = db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    created = not path.exists()
    conn = sqlite3.connect(path)
    try:
        init_schema(conn)
    finally:
        conn.close()
    os.chmod(path, 0o600)
    print(json.dumps({"db": "created" if created else "ready", "mode": "0600"}))


if __name__ == "__main__":
    main()
