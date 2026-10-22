#!/usr/bin/env sh
# Cursor beforeShellExecution tether (eva-emptiness).
# Prefers C binary (eva-tether); falls back to portable shell.
# Shell preference: re-exec under zsh when available; bash/dash/sh must work.
# An unread policy prints deny JSON. A crash with no JSON still allows. No eval.

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
# Own tree first. cursor-agent can export another plugin's root in
# CURSOR_PLUGIN_ROOT/CLAUDE_PLUGIN_ROOT, so an env root counts only when it holds the tether.
ROOT=""
for _try in \
  "${HERE}/../.." \
  "${CURSOR_PLUGIN_ROOT:-}" \
  "${CLAUDE_PLUGIN_ROOT:-}" \
  "${GROK_PLUGIN_ROOT:-}" \
  "${HOME}/Work/personal/plugins/eva-emptiness" \
  "${HOME}/.grok/plugins/eva-emptiness"
do
  if [ -n "$_try" ] && { [ -x "${_try}/bin/eva-tether" ] || [ -f "${_try}/bin/eva-tether-shell.inc" ]; }; then
    ROOT=$(CDPATH= cd -- "$_try" && pwd)
    break
  fi
done

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
if [ -r "${HERE}/eva-tether-shell.inc" ]; then
  INC="${HERE}/eva-tether-shell.inc"
elif [ -n "${ROOT:-}" ] && [ -r "${ROOT}/bin/eva-tether-shell.inc" ]; then
  INC="${ROOT}/bin/eva-tether-shell.inc"
fi

if [ -n "$INC" ]; then
  # shellcheck source=../../bin/eva-tether-shell.inc
  . "$INC"
  eva_tether_shell_main
  exit 0
fi

# Unread policy: deny JSON. A crash with no JSON still allows.
printf '%s\n' '{"permission":"deny","user_message":"eva-emptiness tether: policy unreadable","agent_message":"eva-emptiness tether: policy unreadable"}'
exit 0
