#!/usr/bin/env bash
set -euo pipefail
range="${1:?usage: check-commit-shape.sh BASE..HEAD}"
bad=0
no() { echo "FAIL commit-shape: ${1:0:7} $2"; bad=$((bad + 1)); }
while IFS= read -r c; do
  [[ -z "$c" ]] && continue
  [[ "$(git rev-list --parents -n1 "$c" | wc -w)" -gt 2 ]] && { no "$c" "merge commit"; continue; }
  msg="$(git log -1 --format=%B "$c")"
  for k in Why What Proof; do grep -q "^$k: ." <<< "$msg" || no "$c" "missing $k:"; done
  areas="$(git show --pretty=format: --name-only "$c" | { grep -E '\.(py|js|jsx|mjs|cjs|ts|tsx|go|rs|c|cc|cpp|h|hpp|java|kt|rb|php|swift|cs|sh|bend)$' || true; } | { grep -vE '(^|/)tests?/' || true; } | awk -F/ '{print (NF > 1 ? $1 : ".")}' | sort -u | wc -l)"
  [[ "$areas" -gt 1 ]] && no "$c" "two changes: source in $areas top-level folders"
done < <(git rev-list --reverse "$range")
[[ "$bad" -eq 0 ]] && echo "ok  commit-shape" || exit 1
