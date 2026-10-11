#!/bin/sh
# Armed watch fails closed. No marker and no coordinator means allow.
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
input=$(cat)

watch_armed_shell() {
  cwd=$input
  case $input in
    *\"cwd\":\"*)
      cwd=${input#*\"cwd\":\"}
      cwd=${cwd%%\"*}
      ;;
    *)
      cwd=""
      ;;
  esac
  if [ -z "$cwd" ]; then
    return 1
  fi
  if [ -f "$cwd/.steer/loop.on" ]; then
    return 0
  fi
  if [ -f "$cwd/.steer/now.md" ] && grep -q '^actor:[[:space:]]*coordinator[[:space:]]*$' "$cwd/.steer/now.md"; then
    return 0
  fi
  return 1
}

deny_crash() {
  printf '%s\n' '{"decision":"deny","permission":"deny","reason":"checker crashed"}'
  exit 2
}

allow_quiet() {
  printf '%s\n' '{"decision":"allow","permission":"allow"}'
  exit 0
}

if ! command -v python3 >/dev/null 2>&1; then
  if watch_armed_shell; then
    deny_crash
  fi
  allow_quiet
fi

printf '%s' "$input" | python3 "$HERE/steer_accel.py" hook
status=$?
if [ "$status" -ne 0 ]; then
  if watch_armed_shell; then
    deny_crash
  fi
  allow_quiet
fi
exit 0
