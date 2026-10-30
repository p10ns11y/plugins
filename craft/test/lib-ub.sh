ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }
gitinit() {
  git -C "$1" init -q -b main
  git -C "$1" config user.email craft
  git -C "$1" config user.name craft
  git -C "$1" config commit.gpgsign false
}
repo() {
  local d
  d="$(mktemp -d)"
  gitinit "$d"
  git -C "$d" commit -q --allow-empty -m base
  echo "$d"
}
put() {
  local d="$1" msg="$2" f
  shift 2
  for f in "$@"; do mkdir -p "$d/$(dirname "$f")"; echo "$f $RANDOM" >> "$d/$f"; done
  git -C "$d" add -A
  git -C "$d" commit -qm "$msg"
}
expect() {
  local name="$1" want="$2" d="$3" got=pass
  (cd "$d" && "$CHECK" "$(git rev-list --max-parents=0 HEAD)..HEAD" >/dev/null 2>&1) || got=fail
  rm -rf "$d"
  [[ "$got" == "$want" ]] && ok "$name" || bad "$name wanted $want got $got"
}
finish() {
  echo "---"
  if [[ "$fail" -ne 0 ]]; then echo "$fail failure(s)"; exit 1; fi
  echo "ALL $1 CHECKS PASSED"
}
