#!/usr/bin/env bash
# Door refusals. The checker is the behavior.
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  [[ -f "$ROOT/$1" ]] && ok "exists $1" || bad "missing $1"
}

need plugin.json
need LICENSE
need NOTICE.md
need README.md
need commands/steer-log.md
need agents/steer-log.md
need skills/steer-log/SKILL.md
need skills/steer-log/references/card.md
need bin/steer_log.py
need bin/steer-log

grep -q 'steer-log' "$ROOT/plugin.json" && ok "name" || bad "name"
grep -q 'trust-stack' "$ROOT/skills/steer-log/SKILL.md" && ok "trust-stack stays" || bad "trust-stack"
grep -q 'findings-first' "$ROOT/skills/steer-log/SKILL.md" && ok "findings-first stays" || bad "findings-first"
grep -q '12' "$ROOT/skills/steer-log/references/card.md" && ok "quote floor" || bad "quote floor"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
CHK=(python3 "$ROOT/bin/steer_log.py")

run() {
  local expect=$1
  shift
  set +e
  out=$("${CHK[@]}" "$@" 2>/dev/null)
  rc=$?
  set -e
  if [[ "$rc" -ne "$expect" ]]; then
    bad "$* rc $rc want $expect ($out)"
    return
  fi
  ok "$* → $rc"
}

cat >"$TMP/card.md" <<'EOF'
# Invariant card
- File creates a draft only on File. Fails: `pnpm test file-press`
- A bare budget asks per person or total. Fails: `pnpm test budget-ask`
EOF

cat >"$TMP/feeling.md" <<'EOF'
# Invariant card
- Pixel by pixel, and it feels like magic.
EOF

cat >"$TMP/noop.md" <<'EOF'
- The drawer slides in from the right. Fails: `true`
EOF

cat >"$TMP/log.md" <<'EOF'
| decision | why | verify |
| File creates a draft only on File. | A filed draft was sticking to the next brief. | `pnpm test file-press` |
EOF

cat >"$TMP/doc-ok.md" <<'EOF'
The note quotes the log.

> File creates a draft only on File.
EOF

cat >"$TMP/doc-memory.md" <<'EOF'
Phone steering stays outside this repo. The last half hour was pixel polish.
EOF

cat >"$TMP/doc-foreign.md" <<'EOF'
> Phone steering stays outside this repo.
EOF

python3 - "$TMP" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
# eight lines
lines = ["# Invariant card"]
for i in range(8):
    lines.append(f"- Rule {i} holds in the product. Fails: `pnpm test r{i}`")
(root / "eight.md").write_text("\n".join(lines) + "\n")
PY

run 0 brief "$TMP/card.md"
run 2 brief "$TMP/no-such.md"
run 2 brief "$TMP/feeling.md"
run 2 brief "$TMP/noop.md"
run 2 brief "$TMP/eight.md"
run 0 log "$TMP/log.md"
run 0 doc "$TMP/doc-ok.md" --log "$TMP/log.md"
run 2 doc "$TMP/doc-memory.md" --log "$TMP/log.md"
run 2 doc "$TMP/doc-foreign.md" --log "$TMP/log.md"

# admitted brief points at trust-stack
out=$("${CHK[@]}" brief "$TMP/card.md")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["verdict"]=="admit" and d["next"]=="trust-stack"' "$out" \
  && ok "admit next is trust-stack" || bad "admit next"

if [[ "$fail" -ne 0 ]]; then
  echo "$fail failed"
  exit 1
fi
echo "ok steer-log thin"
