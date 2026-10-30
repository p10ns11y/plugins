#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }
block=$'total = price * qty\ntotal = total - discount\nif total < 0:\n    total = 0'
gen() {
  local n="$1" tag="$2" i
  for ((i = 0; i < n; i++)); do echo "${tag}_v$i = $i + $RANDOM"; done
  echo "$block"
}
d="$(mktemp -d)"
gen 96 a > "$d/a.py"; gen 96 b > "$d/b.py"
out="$("$ROOT/bin/dup-ratio" "$d/a.py" "$d/b.py" || true)"
[[ "$out" == *"dup=4.0%"* ]] && ok "four percent measured" || bad "four percent measured: $out"
"$ROOT/bin/dup-ratio" "$d/a.py" "$d/b.py" >/dev/null 2>&1 && bad "four percent fails" || ok "four percent fails"
gen 196 a > "$d/a.py"; gen 196 b > "$d/b.py"
"$ROOT/bin/dup-ratio" "$d/a.py" "$d/b.py" >/dev/null 2>&1 && ok "two percent passes" || bad "two percent passes"
gen 96 a > "$d/c.py"
"$ROOT/bin/dup-ratio" "$d/c.py" >/dev/null 2>&1 && ok "no repeat passes" || bad "no repeat passes"
git -C "$d" init -q; git -C "$d" config user.email craft; git -C "$d" config user.name craft; git -C "$d" config commit.gpgsign false
git -C "$d" add c.py; git -C "$d" commit -qm base
gen 96 a > "$d/a.py"; gen 96 b > "$d/b.py"; git -C "$d" add -A; git -C "$d" commit -qm touch
(cd "$d" && "$ROOT/bin/dup-ratio" --diff HEAD~1..HEAD >/dev/null 2>&1) && bad "diff mode fails at four percent" || ok "diff mode fails at four percent"
(cd "$d" && { "$ROOT/bin/dup-ratio" --diff HEAD~1..HEAD 2>&1 || true; } | grep -q "files 2") && ok "diff mode scores touched files only" || bad "diff mode scores touched files only"
rm -rf "$d"
echo "---"
if [[ "$fail" -ne 0 ]]; then echo "$fail failure(s)"; exit 1; fi
echo "ALL DUPLICATION CHECKS PASSED"
