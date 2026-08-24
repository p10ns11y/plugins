#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/bin/on-kern"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

[[ -x "$BIN" ]] && ok "on-kern executable" || bad "on-kern missing"

score=$("$BIN" score --cyclops 0.8 --circe 0.2 --drift 0.3)
echo "$score" | grep -q 'harm_cyclops=' && ok "score: harm_cyclops" || bad "score missing harm"
echo "$score" | grep -q 'drift=' && ok "score: drift" || bad "score missing drift"

rank=$("$BIN" rank --cyclops 0.8 --circe 0.2)
echo "$rank" | head -1 | grep -q 'mistake=cyclops' && ok "rank: cyclops first" || bad "rank order"

waters=$("$BIN" waters --calm --file-count 1 --greppable)
echo "$waters" | grep -q 'waters=calm' && ok "waters: calm" || bad "waters calm"
echo "$waters" | grep -q 'metis_allowed=0' && ok "waters: no metis in calm" || bad "metis in calm"

eval_out=$("$BIN" eval --correctness 0.9 --effectiveness 0.7 --efficiency 0.2)
echo "$eval_out" | grep -q 'antidote=YAGNI' && ok "eval: circe/yagni" || bad "eval yagni"

hubris=$("$BIN" hubris --metis 1 --metis-allowed 0)
echo "$hubris" | grep -q 'hubris=1' && ok "hubris: metis refused" || bad "hubris detect"

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
