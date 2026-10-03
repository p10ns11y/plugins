#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export BEND_NO_TELEMETRY=1
if ! command -v bend >/dev/null 2>&1; then
  echo "bend missing" >&2
  exit 2
fi
run() {
  local dir="$1" file="$2" out code=0
  set +e
  out="$(cd "$dir" && bend --verdict "$file" 2>&1)"
  code=$?
  set -e
  printf '%s\n' "$out"
  return "$code"
}
if [[ "${1:-}" == "--self" || $# -eq 0 ]]; then
  fail=0
  miss=0
  env PATH="/usr/bin:/bin" bash "$0" "$ROOT/fixtures/bend/pass" >/dev/null 2>&1 || miss=$?
  if [[ "$miss" -eq 2 ]]; then echo "ok  missing"; else echo "FAIL missing exit=$miss"; fail=$((fail + 1)); fi
  ver="$(bend version)"
  if [[ "$ver" == "bend 2.0.35" ]]; then echo "ok  version"; else echo "FAIL version $ver"; fail=$((fail + 1)); fi
  weak="$(mktemp -d)"
  trap 'rm -rf "$weak"' EXIT
  cp -a "$ROOT/fixtures/bend/pass/." "$weak/"
  cp "$ROOT/fixtures/bend/weak/LAWS.bend" "$weak/LAWS.bend"
  while IFS='|' read -r name dir file expect pat; do
    [[ -z "${name:-}" ]] && continue
    code=0
    set +e
    out="$(run "$dir" "$file")"
    code=$?
    set -e
    if [[ "$code" -eq "$expect" && "$out" == *"$pat"* ]]; then
      echo "ok  $name"
    else
      echo "FAIL $name exit=$code want=$expect"
      printf '%s\n' "$out"
      fail=$((fail + 1))
    fi
  done << EOF
pass|$ROOT/fixtures/bend/pass|PROOF.bend|0|ALL PROOFS CHECK
weak|$weak|PROOF.bend|1|SOME PROOFS FAIL
skip|$ROOT/fixtures/bend/skip|PROOF.bend|1|must import ./LAWS.bend
open|$ROOT/fixtures/bend/open|LAWS.bend|1|TODO
EOF
  echo "---"
  if [[ "$fail" -ne 0 ]]; then echo "$fail failure(s)"; exit 1; fi
  echo "ALL PROOF CHECKS PASSED"
else
  code=0
  set +e
  out="$(run "$1" PROOF.bend)"
  code=$?
  set -e
  printf '%s\n' "$out"
  [[ "$code" -eq 0 && "$out" == *"ALL PROOFS CHECK"* ]] || exit 1
fi
