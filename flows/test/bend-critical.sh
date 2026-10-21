#!/usr/bin/env bash
# Prove flows/bend/LAWS.bend with Bend.
# An absent bend is reported as "formal proof not run". It is never a pass:
# with BEND_REQUIRED=1 (CI proof job) an absent bend fails.
# A bunfig.toml / .env / preload file can forge checker output. Refuse any
# in flows/bend or an ancestor up to the repo root.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
BEND_DIR="$ROOT/bend"

dir="$BEND_DIR"
while :; do
  for f in bunfig.toml .bunfig.toml .env .env.local .p.ts; do
    if [[ -e "$dir/$f" ]]; then
      echo "FAIL forge file $dir/$f near the bend proof"
      exit 1
    fi
  done
  [[ "$dir" == "$REPO" || "$dir" == "/" ]] && break
  dir="$(dirname "$dir")"
done

bend_bin=""
if command -v bend >/dev/null 2>&1; then
  bend_bin="$(command -v bend)"
elif [[ -x "${HOME}/.bend/bin/bend" ]]; then
  bend_bin="${HOME}/.bend/bin/bend"
fi

if [[ -z "$bend_bin" ]]; then
  echo "bend not installed; formal proof not run (https://bend-lang.com/)"
  [[ "${BEND_REQUIRED:-0}" == "1" ]] && exit 1
  exit 0
fi

cd "$BEND_DIR"
ec=0
out="$("$bend_bin" PROOF.bend 2>&1)" || ec=$?
printf '%s\n' "$out"
if [[ "$ec" -ne 0 ]]; then
  echo "FAIL bend exited $ec"
  exit 1
fi
if printf '%s\n' "$out" | grep -qE 'FAIL'; then
  echo "FAIL bend PROOF.bend did not check"
  exit 1
fi
if printf '%s\n' "$out" | grep -q 'ALL PROOFS CHECK'; then
  exit 0
fi
echo "FAIL bend PROOF.bend did not check"
exit 1
