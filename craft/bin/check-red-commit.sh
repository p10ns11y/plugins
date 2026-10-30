#!/usr/bin/env bash
set -euo pipefail
range="${1:?usage: check-red-commit.sh BASE..HEAD}"
kind() {
  local p="$1" b="${1##*/}"
  if [[ "$p" =~ (^|/)tests?/ || "$b" == test_* || "$b" =~ _test\.[a-z]+$ || "$b" =~ \.(spec|test)\.[a-z]+$ ]]; then echo test
  elif [[ "$b" =~ \.(py|js|jsx|mjs|cjs|ts|tsx|go|rs|c|cc|cpp|h|hpp|java|kt|rb|php|swift|cs|sh|bend)$ ]]; then echo prod
  else echo other; fi
}
red=0
while IFS= read -r c; do
  [[ -z "$c" ]] && continue
  t=0 p=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$(kind "$f")" in test) t=1 ;; prod) p=1 ;; esac
  done < <(git show --pretty=format: --name-only "$c")
  if [[ "$p" -eq 1 ]]; then
    [[ "$red" -eq 1 ]] && { echo "ok  red-commit"; exit 0; }
    echo "FAIL red-commit: ${c:0:7} changes source before a test-only commit with a failing Red-run"
    exit 1
  fi
  if [[ "$t" -eq 1 ]] && git log -1 --format=%B "$c" | grep -qiE '^Red-run:.*(fail|error|not ok|panicked)'; then red=1; fi
done < <(git rev-list --reverse --no-merges "$range")
echo "ok  red-commit"
