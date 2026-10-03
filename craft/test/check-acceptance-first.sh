#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

kind_of() {
  local p b e
  p="${1//\\//}"
  b="${p##*/}"
  e="${b##*.}"
  e="${e,,}"
  if [[ "$b" == LAWS.bend ]]; then echo accept
  elif [[ "$p" =~ (^|/)tests?/ || "$b" == test_*.py || "$b" == *_test.py || "$b" =~ \.(spec|test)\.(py|js|jsx|ts|tsx|java)$ ]]; then echo test
  elif [[ "$e" == bend || "$e" =~ ^(py|js|jsx|mjs|cjs|ts|tsx|go|rs|c|cc|cpp|h|hpp|java|kt|scala|rb|php|swift|cs|vue|svelte|lua|sh|sql|css|html)$ ]]; then echo prod
  elif [[ "$p" == *.feature || "$p" =~ (^|/)features/ || "$p" =~ (^|/)qa/ ]]; then echo accept
  elif [[ "$e" =~ ^(md|rst|txt|adoc|markdown)$ ]]; then echo doc
  elif [[ "$b" != *.* || "$b" == .* || "$e" =~ ^(yml|yaml|json|toml|ini|cfg|conf|csv|tsv|xml|lock|properties|png|jpg|jpeg|gif|svg|webp|ico)$ || "$p" =~ (^|/)fixtures/ ]]; then echo neutral
  else echo unknown; fi
}
read_files() {
  has_a=0
  has_p=0
  local f k
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    k="$(kind_of "$f")"
    if [[ "$k" == unknown ]]; then echo "unknown extension: $f"; return 1; fi
    [[ "$k" == prod ]] && has_p=1
    [[ "$k" == accept ]] && has_a=1
  done
  return 0
}
check_range() {
  local range="$1" seen_a=0 seen_p=0 commit left f commits
  if [[ "$range" == *..* && "$range" != *...* ]]; then
    left="${range%%..*}"
    if [[ -n "$left" ]]; then
      git rev-parse --verify "${left}^{commit}" >/dev/null 2>&1 || { echo "bad range base $left"; return 1; }
      while IFS= read -r f; do
        [[ -n "$f" && "$(kind_of "$f")" == accept ]] && seen_a=1
      done < <(git ls-tree -r --name-only "$left") || true
    fi
  fi
  commits="$(git log --reverse --format=%H "$range")" || { echo "git log failed for $range"; return 1; }
  while IFS= read -r commit; do
    [[ -z "$commit" ]] && continue
    read_files < <(git show --pretty=format: --name-only "$commit") || return 1
    if [[ "$has_p" -eq 1 && "$seen_a" -eq 0 && "$has_a" -eq 0 ]]; then
      echo "production before acceptance in commit $commit"
      return 1
    fi
    if [[ "$has_a" -eq 1 && "$seen_p" -eq 1 ]]; then
      echo "acceptance after production in commit $commit"
      return 1
    fi
    [[ "$has_a" -eq 1 ]] && seen_a=1
    [[ "$has_p" -eq 1 ]] && seen_p=1
  done <<< "$commits"
  if [[ "$seen_p" -eq 1 && "$seen_a" -eq 0 ]]; then
    echo "production without acceptance in $range"
    return 1
  fi
}
apply_repo() {
  local name="$1" expect="$2" src="$3" dir step got=fail msg
  dir="$(mktemp -d)"
  git -C "$dir" init -q
  git -C "$dir" config user.email craft
  git -C "$dir" config user.name craft
  git -C "$dir" config commit.gpgsign false
  for step in "$src"/*; do
    cp -a "$step"/. "$dir"/
    find "$dir" -path "$dir/.git" -prune -o -type f -exec touch {} +
    git -C "$dir" add -A && git -C "$dir" commit -qm step
  done
  msg="$(cd "$dir" && check_range HEAD 2>&1 || true)"
  [[ -z "$msg" ]] && got=pass
  if [[ "$name" == fail-laws && "$msg" != *"acceptance after production"* ]]; then
    bad "fail-laws reason"
  fi
  if [[ "$name" == pass-first ]]; then
    (cd "$dir" && check_range HEAD~1..HEAD >/dev/null) && ok "range-base" || bad "range-base"
  fi
  rm -rf "$dir"
  [[ "$got" == "$expect" ]] && ok "$name" || bad "$name wanted $expect got $got"
}
if [[ "${1:-}" == "--self" || $# -eq 0 ]]; then
  for case in "$ROOT/fixtures/order"/*; do
    name="$(basename "$case")"
    if [[ "$name" == pass-* ]]; then apply_repo "$name" pass "$case"; else apply_repo "$name" fail "$case"; fi
  done
else
  check_range "$1" && ok "range $1" || bad "range $1"
fi
echo "---"
if [[ "$fail" -ne 0 ]]; then echo "$fail failure(s)"; exit 1; fi
echo "ALL ACCEPTANCE CHECKS PASSED"
