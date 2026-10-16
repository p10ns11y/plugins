#!/usr/bin/env sh
# PreToolUse Bash tether for eva-emptiness (Grok).
# Prefers C binary (eva-tether); falls back to portable shell.
# Shell preference: re-exec under zsh when available; bash/dash/sh must work.
# Explicit deny JSON blocks; fail-open on crash (Grok contract).
# No eval. No always-approve path.

# Capture script path at top level (zsh: $0 inside functions is the function name).
EVA_TETHER_ARG0=$0

# zsh first when available (skip if already under zsh or re-exec disabled)
if [ -z "${EVA_TETHER_REEXEC:-}" ] && [ -z "${ZSH_VERSION:-}" ]; then
  if command -v zsh >/dev/null 2>&1; then
    EVA_TETHER_REEXEC=1
    export EVA_TETHER_REEXEC
    exec zsh "$EVA_TETHER_ARG0" "$@"
  fi
fi

# Strict mode: pipefail when the shell supports it
set -eu
# shellcheck disable=SC3040
(set -o pipefail) 2>/dev/null && set -o pipefail

EVA_TETHER_MODE=grok
export EVA_TETHER_MODE

# Resolve directory containing this script (POSIX; works under zsh/bash/dash).
HERE=$(CDPATH= cd -- "$(dirname -- "$EVA_TETHER_ARG0")" && pwd)
ROOT=${CLAUDE_PLUGIN_ROOT:-${GROK_PLUGIN_ROOT:-}}
if [ -z "$ROOT" ]; then
  ROOT=$(CDPATH= cd -- "$HERE/.." && pwd)
fi

# Candidate C binaries (first executable wins)
for _cand in \
  "${HERE}/eva-tether" \
  "${ROOT}/bin/eva-tether" \
  "${HOME}/.local/bin/eva-tether"
do
  if [ -n "$_cand" ] && [ -x "$_cand" ]; then
    exec "$_cand" --mode=grok
  fi
done

# Shell fallback. A candidate counts only when it is readable.
INC=""
for _inc in \
  "${HERE}/eva-tether-shell.inc" \
  "${ROOT}/bin/eva-tether-shell.inc"
do
  if [ -r "$_inc" ]; then
    INC="$_inc"
    break
  fi
done
if [ -n "$INC" ]; then
  # shellcheck source=eva-tether-shell.inc
  . "$INC"
  eva_tether_shell_main
  exit 0
fi

# Unread policy: deny JSON. A crash with no JSON still allows.
printf '%s\n' '{"decision":"deny","reason":"eva-emptiness tether: policy unreadable"}'
exit 0
