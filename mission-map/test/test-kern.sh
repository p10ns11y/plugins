#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
BIN="$ROOT/bin/mm-kern"

te=$("$BIN" pert 2 4 8)
case "$te" in
  te=4.333333*) ;;
  *) echo "unexpected pert: $te" >&2; exit 1 ;;
esac

grad=$("$BIN" grad 2 4 8)
case "$grad" in
  dte_dm=0.666667*) ;;
  *) echo "unexpected grad: $grad" >&2; exit 1 ;;
esac

mc=$("$BIN" mc 2 4 8 1 3 5)
case "$mc" in
  mean=*) ;;
  *) echo "unexpected mc: $mc" >&2; exit 1 ;;
esac

if "$BIN" pert 8 4 2; then
  echo "expected invalid stage to fail" >&2
  exit 1
fi

echo "test-kern ok"
