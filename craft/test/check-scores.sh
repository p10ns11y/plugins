#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/bin"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }
if ! python3 -c "import pytest, coverage" 2>/dev/null; then
  echo "pytest and coverage are required" >&2
  exit 2
fi
export PYTHONDONTWRITEBYTECODE=1
empty="$(mktemp -d)"
diffrepo="$(mktemp -d)"
trap 'rm -rf "$empty" "$diffrepo"' EXIT
python3 -m venv --without-pip "$empty"
bare="$empty/bin/python"
git -C "$diffrepo" init -q
git -C "$diffrepo" config user.email craft
git -C "$diffrepo" config user.name craft
git -C "$diffrepo" config commit.gpgsign false
printf '%s\n' 'def keep():' '    return 1' '' 'def touch(n):' '    if n > 0:' '        return n' '    return 0' > "$diffrepo/lib.py"
printf '%s\n' 'from lib import keep, touch' 'def test_both():' '    assert keep() == 1' '    assert touch(2) == 2 and touch(0) == 0' > "$diffrepo/test_lib.py"
git -C "$diffrepo" add lib.py test_lib.py
git -C "$diffrepo" commit -qm base
python3 -c 'import pathlib,sys; p=pathlib.Path(sys.argv[1]); p.write_text(p.read_text().replace("        return n\n","        return n + 0\n"))' "$diffrepo/lib.py"
git -C "$diffrepo" add lib.py
git -C "$diffrepo" commit -qm edit

run() {
  local name="$1" expect="$2" pats="$3"
  shift 3
  local out code p okp=1
  set +e
  out="$("$@" 2>&1)"
  code=$?
  set -e
  IFS='~' read -ra arr <<< "$pats"
  for p in "${arr[@]}"; do
    [[ -z "$p" ]] && continue
    [[ "$out" == *"$p"* ]] || okp=0
  done
  if [[ "$code" -eq "$expect" && "$okp" -eq 1 ]]; then
    ok "$name"
  else
    bad "$name exit=$code want=$expect"
    printf '%s\n' "$out" | head -20
  fi
}

while IFS='|' read -r name expect pats args; do
  [[ -z "${name:-}" || "$name" == \#* ]] && continue
  # shellcheck disable=SC2086
  run "$name" "$expect" "$pats" $args
done << EOF
good-crap|0|scope=file~inc: comp=1 cov=1.00|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/good/lib.py $ROOT/fixtures/good/test_lib.py
good-mut|0|scope=file~mutation_score=1.00|python3 $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/good/lib.py $ROOT/fixtures/good/test_lib.py
bad-crap|1|messy:|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/bad-crap/lib.py $ROOT/fixtures/bad-crap/test_lib.py
bad-split|1|uncovered: comp=4 cov=0.00 crap=20.00|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/bad-split-cov/lib.py $ROOT/fixtures/bad-split-cov/test_lib.py
uncalled|1|uncalled: comp=3 cov=0.00 crap=12.00|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/uncalled/lib.py $ROOT/fixtures/uncalled/test_lib.py
uncalled-oneliner|1|never: comp=3 cov=0.00 crap=12.00|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/uncalled/lib.py $ROOT/fixtures/uncalled/test_lib.py
methods|1|Cart.total: comp=3 cov=0.00 crap=12.00~load: comp=3 cov=0.00 crap=12.00|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/methods/lib.py $ROOT/fixtures/methods/test_lib.py
methods-mut|1|Cart.total: mutation_score=0.00~load: mutation_score=0.00|python3 $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/methods/lib.py $ROOT/fixtures/methods/test_lib.py
branches|0|tern: comp=4~using: comp=1~matchy: comp=4~multi: comp=3~kept: comp=4|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/branches/lib.py $ROOT/fixtures/branches/test_lib.py
bad-mut|1|mutation_score=0.00 mutants=2 killed=0|python3 $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/bad-mutants/lib.py $ROOT/fixtures/bad-mutants/test_lib.py
sibling|1|mutation_score=0.00 mutants=2 killed=0|python3 $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/sibling/lib.py $ROOT/fixtures/sibling/test_lib.py
red-suite|2|unmutated suite failed|python3 $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/red-suite/lib.py $ROOT/fixtures/red-suite/test_lib.py
red-crap|2|coverage suite failed|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/red-suite/lib.py $ROOT/fixtures/red-suite/test_lib.py
no-mutants|2|no mutants|python3 $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/no-mutants/lib.py $ROOT/fixtures/no-mutants/test_lib.py
syntax-mut|2|no mutants|python3 $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/syntax-mut/lib.py $ROOT/fixtures/syntax-mut/test_lib.py
no-fn-crap|2|no functions|python3 $BIN/crap-score.py --max 6 $ROOT/fixtures/no-functions/lib.py $ROOT/fixtures/no-functions/test_lib.py
no-fn-mut|2|no functions|python3 $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/no-functions/lib.py $ROOT/fixtures/no-functions/test_lib.py
fn-uncovered|1|scope=functions functions=uncovered~crap=20.00|python3 $BIN/crap-score.py --max 6 --functions uncovered $ROOT/fixtures/bad-split-cov/lib.py $ROOT/fixtures/bad-split-cov/test_lib.py
fn-covered|0|scope=functions functions=covered~crap=1.00|python3 $BIN/crap-score.py --max 6 --functions covered $ROOT/fixtures/bad-split-cov/lib.py $ROOT/fixtures/bad-split-cov/test_lib.py
fn-missing|2|unknown functions|python3 $BIN/crap-score.py --max 6 --functions nope $ROOT/fixtures/good/lib.py $ROOT/fixtures/good/test_lib.py
bad-diff|2|fatal: bad revision|python3 $BIN/crap-score.py --max 6 --diff NO_SUCH_REV $ROOT/fixtures/good/lib.py $ROOT/fixtures/good/test_lib.py
diff-touch|0|scope=diff functions=touch|python3 $BIN/crap-score.py --max 6 --diff HEAD~1..HEAD $diffrepo/lib.py $diffrepo/test_lib.py
miss-pytest|2|pytest missing|$bare $BIN/mutation-score.py --min 0.95 $ROOT/fixtures/good/lib.py $ROOT/fixtures/good/test_lib.py
miss-cov|2|coverage missing|$bare $BIN/crap-score.py --max 6 $ROOT/fixtures/good/lib.py $ROOT/fixtures/good/test_lib.py
EOF

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL SCORE CHECKS PASSED"
exit 0
