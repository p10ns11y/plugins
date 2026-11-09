#!/usr/bin/env python3
"""Return one verified pulse, or a few, never the whole store.

  pulse_retrieve.py QUERY
  pulse_retrieve.py --key NAT_KEY
  pulse_retrieve.py --prefetch PREFETCH_KEY
  pulse_retrieve.py --limit N QUERY
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pulse_common import MAX_RETRIEVE, connect, retrieve


def main():
    args = sys.argv[1:]
    key = None
    prefetch = None
    limit = 1
    query_parts = []
    i = 0
    while i < len(args):
        token = args[i]
        if token == "--key":
            if i + 1 >= len(args):
                print("usage: pulse_retrieve.py --key NAT_KEY", file=sys.stderr)
                sys.exit(2)
            key = args[i + 1]
            i += 2
            continue
        if token in ("--prefetch", "--prefetch-key"):
            if i + 1 >= len(args):
                print("usage: pulse_retrieve.py --prefetch PREFETCH_KEY", file=sys.stderr)
                sys.exit(2)
            prefetch = args[i + 1]
            i += 2
            continue
        if token == "--limit":
            if i + 1 >= len(args):
                print("usage: pulse_retrieve.py --limit N QUERY", file=sys.stderr)
                sys.exit(2)
            limit = args[i + 1]
            i += 2
            continue
        if token in ("-h", "--help"):
            print(
                "usage: pulse_retrieve.py QUERY\n"
                "       pulse_retrieve.py --key NAT_KEY\n"
                "       pulse_retrieve.py --prefetch PREFETCH_KEY\n"
                f"       pulse_retrieve.py --limit N QUERY   (max {MAX_RETRIEVE})"
            )
            return
        query_parts.append(token)
        i += 1
    query = " ".join(query_parts)
    conn = connect()
    try:
        result = retrieve(
            conn,
            query=query,
            limit=limit,
            key=key,
            prefetch_key=prefetch,
        )
        print(json.dumps(result, ensure_ascii=False))
        sys.exit(0)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
