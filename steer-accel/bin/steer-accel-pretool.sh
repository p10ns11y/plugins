#!/bin/sh
# Opt-in. No .steer/loop.on means allow. A crash in the checker allows too.
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if ! command -v python3 >/dev/null 2>&1; then
  printf '%s\n' '{"decision":"allow"}'
  exit 0
fi
python3 "$HERE/steer_accel.py" hook
exit 0
