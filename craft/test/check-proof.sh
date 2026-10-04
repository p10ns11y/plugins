#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export BEND_NO_TELEMETRY=1
if ! command -v bend >/dev/null 2>&1; then echo "bend missing" >&2; exit 2; fi
prove() {
  local out code=0
  set +e; out="$(cd "$1" && bend --verdict "$2" 2>&1)"; code=$?; set -e
  if [[ "$code" -eq "$3" && "$out" == *"$4"* ]]; then
    [[ -n "${5:-}" ]] && echo "ok  $5" || printf '%s\n' "$out"
    return 0
  fi
  [[ -n "${5:-}" ]] && echo "FAIL $5 exit=$code want=$3"; printf '%s\n' "$out"; return 1
}
[[ "${1:-}" != "--self" && $# -ne 0 ]] && { prove "$1" PROOF.bend 0 "ALL PROOFS CHECK"; exit; }
fail=0 miss=0
env PATH="/usr/bin:/bin" bash "$0" "$ROOT/fixtures/bend/pass" >/dev/null 2>&1 || miss=$?
[[ "$miss" -eq 2 ]] && echo "ok  missing" || { echo "FAIL missing"; fail=$((fail + 1)); }
[[ "$(bend version)" == "bend 2.0.35" ]] && echo "ok  version" || { echo "FAIL version"; fail=$((fail + 1)); }
w="$(mktemp -d)"; trap 'rm -rf "$w"' EXIT; mkdir -p "$w/w" "$w/s"
cp -a "$ROOT/fixtures/bend/pass/." "$w/w"; cp "$ROOT/fixtures/bend/weak/LAWS.bend" "$w/w/LAWS.bend"
cp "$ROOT/fixtures/bend/pass/LAWS.bend" "$ROOT/fixtures/bend/skip/PROOF.bend" "$w/s/"
while IFS='|' read -r n d f e p; do prove "$d" "$f" "$e" "$p" "$n" || fail=$((fail + 1)); done << EOF
pass|$ROOT/fixtures/bend/pass|PROOF.bend|0|ALL PROOFS CHECK
weak|$w/w|PROOF.bend|1|SOME PROOFS FAIL
skip|$w/s|PROOF.bend|1|must import ./LAWS.bend
open|$ROOT/fixtures/bend/pass|LAWS.bend|1|TODO
EOF
[[ "$fail" -eq 0 ]] && echo "ALL PROOF CHECKS PASSED" || { echo "$fail failure(s)"; exit 1; }
