#!/usr/bin/env bash
# Prove flows/bend/LAWS.bend when Bend is installed.
# An absent bend is reported as not run. It is not a pass.
# A bunfig.toml beside the proof can forge "All terms check." Refuse that.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BEND_DIR="$ROOT/bend"

if [[ -e "$BEND_DIR/bunfig.toml" || -e "$BEND_DIR/.env" || -e "$BEND_DIR/.p.ts" ]]; then
  echo "FAIL bend proof directory contains a forge (bunfig.toml, .env, or .p.ts)"
  exit 1
fi

bend_bin=""
if command -v bend >/dev/null 2>&1; then
  bend_bin="$(command -v bend)"
elif [[ -x "${HOME}/.bend/bin/bend" ]]; then
  bend_bin="${HOME}/.bend/bin/bend"
fi

if [[ -z "$bend_bin" ]]; then
  echo "bend not installed; formal proof not run (https://bend-lang.com/)"
  exit 0
fi

cd "$BEND_DIR"
out="$("$bend_bin" PROOF.bend)"
printf '%s\n' "$out"
if printf '%s\n' "$out" | grep -q 'SOME PROOFS FAIL'; then
  echo "FAIL bend PROOF.bend did not check"
  exit 1
fi
if printf '%s\n' "$out" | grep -q 'ALL PROOFS CHECK' || printf '%s\n' "$out" | grep -q 'All terms check.'; then
  exit 0
fi
echo "FAIL bend PROOF.bend did not check"
exit 1
