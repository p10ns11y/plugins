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

cat >"$TMP/doc-half.md" <<'EOF'
The last half hour was pixel polish.

> File creates a draft only on File.
EOF
run 2 doc "$TMP/doc-half.md" --log "$TMP/log.md"
set +e
out=$("${CHK[@]}" doc "$TMP/doc-half.md" --log "$TMP/log.md" 2>/dev/null)
set -e
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["reason"]=="steering doc is not only a log quote"' "$out" \
  && ok "narrative refused" || bad "narrative ($out)"

cat >"$TMP/feeling-command.md" <<'EOF'
- It feels like magic. Fails: `pnpm test mood`
EOF
run 0 brief "$TMP/feeling-command.md"

# log seals a snapshot and refuses an edited older row
[[ -f "$TMP/log.md.prior" ]] && ok "log snapshot" || bad "log snapshot"
cat >"$TMP/log.md" <<'EOF'
| decision | why | verify |
| File creates a draft only on File. | A filed draft was sticking to the next brief. | `pnpm test file-press` |
| Prices stay in their own currency. | A conversion was a guess. | `pnpm test currency` |
EOF
run 0 log "$TMP/log.md"
cat >"$TMP/log.md" <<'EOF'
| decision | why | verify |
| File creates a draft on any click. | rewritten | `pnpm test file-press` |
| Prices stay in their own currency. | A conversion was a guess. | `pnpm test currency` |
EOF
run 2 log "$TMP/log.md"
set +e
out=$("${CHK[@]}" log "$TMP/log.md" 2>/dev/null)
set -e
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["reason"]=="older decision was edited"' "$out" \
  && ok "edited older row" || bad "edited older row ($out)"
grep -q 'only on File' "$TMP/log.md.prior" && ok "snapshot kept" || bad "snapshot kept"

# admitted brief points at trust-stack
out=$("${CHK[@]}" brief "$TMP/card.md")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["verdict"]=="admit" and d["next"]=="trust-stack"' "$out" \
  && ok "admit next is trust-stack" || bad "admit next"

pre_good() {
  mkdir -p "$TMP/pre"
  printf '%s\n' 'pnpm test drawer-slides' 'pnpm test file-press' >"$TMP/pre/interactions"
  printf '%s\n' '#!/bin/sh' 'python3 -c "import json,sys; json.dump({\"ok\": True}, sys.stdout)"' >"$TMP/pre/verify"
  printf '%s\n' 'Short pull request body. What changed and why.' >"$TMP/pre/prose"
  printf '%s\n' 'builder' >"$TMP/pre/writers"
  printf '%s\n' '# Invariant card' '- File creates a draft only on File. Fails: `pnpm test file-press`' >"$TMP/pre/invariant.md"
  printf '%s\n' 'connector: `pnpm test vercel-list`' 'Redeploy and smoke.' >"$TMP/pre/host"
}

pre_good
run 0 pre "$TMP/pre"
printf '%s\n' 'npx impeccable detect' >"$TMP/pre/interactions"
run 2 pre "$TMP/pre"
pre_good
printf '%s\n' 'import openai' 'print("json")' >"$TMP/pre/verify"
run 2 pre "$TMP/pre"
pre_good
printf '%s\n' 'This page is a demo of the flow.' >"$TMP/pre/prose"
run 2 pre "$TMP/pre"
pre_good
python3 -c 'open("'"$TMP"'/pre/prose","w").write(("word "*121).strip())'
run 2 pre "$TMP/pre"
pre_good
printf '%s\n' 'builder' 'second' >"$TMP/pre/writers"
run 2 pre "$TMP/pre"
pre_good
printf '%s\n' '- A bare budget asks per person or total. Fails: `pnpm test budget-ask`' >>"$TMP/pre/invariant.md"
run 2 pre "$TMP/pre"
pre_good
printf '%s\n' 'connector: `pnpm test vercel-list`' 'Add the keys before smoke.' >"$TMP/pre/host"
run 2 pre "$TMP/pre"
pre_good
printf '%s\n' 'connector: `vercel ls --team-id abc`' >"$TMP/pre/host"
run 2 pre "$TMP/pre"
rm -f "$TMP/pre/interactions"
run 2 pre "$TMP/pre"

if [[ "$fail" -ne 0 ]]; then
  echo "$fail failed"
  exit 1
fi
echo "ok steer-log thin"
