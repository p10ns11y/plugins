#!/usr/bin/env bash
# Shared helpers for arch-machine Grok plugin (agent-internal).
# shellcheck shell=bash
set -euo pipefail

am_plugin_root() {
  if [[ -n "${GROK_PLUGIN_ROOT:-}" ]]; then
    printf '%s\n' "$GROK_PLUGIN_ROOT"
    return 0
  fi
  # Resolve relative to this script when not launched via Grok
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  printf '%s\n' "$here"
}

am_core_map_path() {
  local root
  root="$(am_plugin_root)"
  printf '%s\n' "$root/core-map.json"
}

# Require jq for machine-readable map (tests + helpers).
am_need_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "jq is required to parse core-map.json" >&2
    return 1
  }
}

# Print JSON field from core-map (path is jq expression under root).
am_map_get() {
  am_need_jq
  local expr="$1"
  jq -r "$expr" "$(am_core_map_path)"
}

# Returns 0 if action is on FSD allowlist (read-only / non-mutating).
am_fsd_allowed() {
  am_need_jq
  local action="$1"
  jq -e --arg a "$action" '.modes.fsd.allowlist | index($a) != null' "$(am_core_map_path)" >/dev/null
}

# Returns 0 if action is listed as requiring --yes.
am_requires_consent() {
  am_need_jq
  local action="$1"
  jq -e --arg a "$action" '.modes.fsd.deny_without_yes | index($a) != null' "$(am_core_map_path)" >/dev/null
}

# Fail closed: mutating actions need --yes.
# Usage: am_consent_gate <action> [--yes]
# Exits 2 without consent when action requires it.
am_consent_gate() {
  local action="$1"
  shift || true
  local yes=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes|-y) yes=1; shift ;;
      *) shift ;;
    esac
  done

  if am_requires_consent "$action"; then
    if [[ "$yes" -ne 1 ]]; then
      echo "consent_required: action='$action' needs --yes (fail closed)" >&2
      echo "fsd: not on allowlist for unsupervised mutation" >&2
      return 2
    fi
  fi
  return 0
}

# Is tier expandable (profile or module name)?
am_is_expandable() {
  am_need_jq
  local name="$1"
  jq -e --arg n "$name" '
    (.expandable.profiles | has($n)) or (.expandable.modules | has($n))
  ' "$(am_core_map_path)" >/dev/null
}

am_is_core_binary() {
  am_need_jq
  local name="$1"
  jq -e --arg n "$name" '.core.binaries | index($n) != null' "$(am_core_map_path)" >/dev/null
}

# Resolve arch-machine root for operations (never invent secrets).
# Order: ARCH_MACHINE_ROOT, /usr/share/tinfoil (if install.sh present), GROK override.
am_resolve_repo() {
  if [[ -n "${ARCH_MACHINE_ROOT:-}" && -d "$ARCH_MACHINE_ROOT" ]]; then
    printf '%s\n' "$ARCH_MACHINE_ROOT"
    return 0
  fi
  if [[ -f /usr/share/tinfoil/install.sh ]]; then
    printf '%s\n' /usr/share/tinfoil
    return 0
  fi
  # Common clone locations (status only — do not create)
  local c
  for c in \
    "$HOME/arch-machine" \
    "$HOME/Work/personal/arch-machine" \
    "$HOME/.cache/arch-machine/src"
  do
    if [[ -f "$c/install.sh" ]]; then
      printf '%s\n' "$c"
      return 0
    fi
  done
  return 1
}

am_expand_home() {
  local p="$1"
  p="${p/#\~/$HOME}"
  printf '%s\n' "$p"
}
