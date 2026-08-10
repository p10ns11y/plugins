#!/usr/bin/env sh
# Cursor beforeShellExecution tether (eva-emptiness).
# Prefers C binary (eva-tether); falls back to portable shell.
# Shell preference: re-exec under zsh when available; bash/dash/sh must work.
# Deny trauma patterns; fail-open if unreadable. No eval.

# Capture script path at top level (zsh: $0 inside functions is the function name).
EVA_TETHER_ARG0=$0

if [ -z "${EVA_TETHER_REEXEC:-}" ] && [ -z "${ZSH_VERSION:-}" ]; then
  if command -v zsh >/dev/null 2>&1; then
    EVA_TETHER_REEXEC=1
    export EVA_TETHER_REEXEC
    exec zsh "$EVA_TETHER_ARG0" "$@"
  fi
fi

set -eu
# shellcheck disable=SC3040
(set -o pipefail) 2>/dev/null && set -o pipefail

EVA_TETHER_MODE=cursor
export EVA_TETHER_MODE

HERE=$(CDPATH= cd -- "$(dirname -- "$EVA_TETHER_ARG0")" && pwd)
ROOT=${GROK_PLUGIN_ROOT:-}
if [ -z "$ROOT" ]; then
  for _try in \
    "${HERE}/../.." \
    "${HOME}/Work/personal/plugins/eva-emptiness" \
    "${HOME}/.grok/plugins/eva-emptiness"
  do
    if [ -x "${_try}/bin/eva-tether" ] || [ -f "${_try}/bin/eva-tether-shell.inc" ]; then
      ROOT=$(CDPATH= cd -- "$_try" && pwd)
      break
    fi
  done
fi

for _cand in \
  "${HERE}/eva-tether" \
  "${ROOT:+$ROOT/bin/eva-tether}" \
  "${HOME}/.local/bin/eva-tether"
do
  if [ -n "$_cand" ] && [ -x "$_cand" ]; then
    exec "$_cand" --mode=cursor
  fi
done

INC=""
if [ -f "${HERE}/eva-tether-shell.inc" ]; then
  INC="${HERE}/eva-tether-shell.inc"
elif [ -n "${ROOT:-}" ] && [ -f "${ROOT}/bin/eva-tether-shell.inc" ]; then
  INC="${ROOT}/bin/eva-tether-shell.inc"
fi

if [ -n "$INC" ]; then
  # shellcheck source=../../bin/eva-tether-shell.inc
  . "$INC"
  eva_tether_shell_main
  exit 0
fi

# Fail-open for Cursor: explicit allow
printf '%s\n' '{"permission":"allow"}'
exit 0
