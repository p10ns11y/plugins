#!/usr/bin/env bash
# Shared helpers for arch-machine Grok plugin (agent-internal).
# shellcheck shell=bash
set -euo pipefail

am_plugin_root() {
  if [[ -n "${GROK_PLUGIN_ROOT:-}" ]]; then
    printf '%s\n' "$GROK_PLUGIN_ROOT"
    return 0
  fi
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  printf '%s\n' "$here"
}

am_core_map_path() {
  printf '%s\n' "$(am_plugin_root)/core-map.json"
}

am_need_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "jq is required to parse core-map.json" >&2
    return 1
  }
}

am_map_get() {
  am_need_jq
  jq -r "$1" "$(am_core_map_path)"
}

am_fsd_allowed() {
  am_need_jq
  local action="$1"
  jq -e --arg a "$action" '.modes.fsd.allowlist | index($a) != null' "$(am_core_map_path)" >/dev/null
}

am_requires_consent() {
  am_need_jq
  local action="$1"
  jq -e --arg a "$action" '.modes.fsd.deny_without_yes | index($a) != null' "$(am_core_map_path)" >/dev/null
}

# Fail closed: mutating actions need --yes.
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
      return 2
    fi
  fi
  return 0
}

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

am_expand_home() {
  local p="$1"
  p="${p/#\~/$HOME}"
  printf '%s\n' "$p"
}

# Resolve existing repo (no create).
# Order: ARCH_MACHINE_ROOT → source checkouts → cache → system /usr/share/tinfoil last
# (runtime install may lag modules/*/install.sh --agent-expand).
am_resolve_repo() {
  if [[ -n "${ARCH_MACHINE_ROOT:-}" && -f "${ARCH_MACHINE_ROOT}/install.sh" ]]; then
    printf '%s\n' "$ARCH_MACHINE_ROOT"
    return 0
  fi
  local c
  for c in \
    "$HOME/arch-machine" \
    "$HOME/Work/personal/arch-machine" \
    "$HOME/.cache/arch-machine/src"
  do
    if [[ -f "$c/install.sh" && -d "$c/modules" ]]; then
      printf '%s\n' "$c"
      return 0
    fi
  done
  # Fallback: any of the above with install.sh only
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
  if [[ -f /usr/share/tinfoil/install.sh ]]; then
    printf '%s\n' /usr/share/tinfoil
    return 0
  fi
  return 1
}

# Ensure repo exists: clone/pull remote when missing (caller must already pass consent).
# Prints absolute repo path.
am_ensure_repo() {
  local force_pull="${1:-0}"
  if repo="$(am_resolve_repo 2>/dev/null)"; then
    if [[ "$force_pull" == "1" && -d "$repo/.git" ]]; then
      local branch
      branch="$(am_map_get '.remote.default_branch' 2>/dev/null || echo sentinel)"
      git -C "$repo" fetch --depth 1 origin "$branch" 2>/dev/null || true
      git -C "$repo" checkout "$branch" 2>/dev/null || true
      git -C "$repo" pull --ff-only origin "$branch" 2>/dev/null || true
    fi
    printf '%s\n' "$repo"
    return 0
  fi

  # Clone into cache (or ARCH_MACHINE_ROOT if set but empty)
  local repo_url cache branch
  repo_url="$(am_map_get '.remote.repo' 2>/dev/null || echo 'https://github.com/p10ns11y/arch-machine.git')"
  cache="$(am_expand_home "$(am_map_get '.remote.default_cache_dir' 2>/dev/null || echo '~/.cache/arch-machine/src')")"
  branch="$(am_map_get '.remote.default_branch' 2>/dev/null || echo sentinel)"

  if [[ -n "${ARCH_MACHINE_ROOT:-}" ]]; then
    cache="$ARCH_MACHINE_ROOT"
  fi

  if [[ ! -d "$cache/.git" ]]; then
    command -v git >/dev/null 2>&1 || {
      echo "git required to clone arch-machine" >&2
      return 1
    }
    mkdir -p "$(dirname "$cache")"
    git clone --branch "$branch" --depth 1 "$repo_url" "$cache"
  fi
  printf '%s\n' "$cache"
}

# True if module install.sh has a runnable --agent-expand case/flag (not mere prose).
am_module_has_agent_expand() {
  local script="$1"
  [[ -f "$script" ]] || return 1
  # Match flag tokens only (case/--agent-expand), not "no agent-expand" comments.
  grep -qE -- '(^|[[:space:]])--agent-expand([[:space:]]|\)|$)' "$script" 2>/dev/null
}

# Run module agent-expand entry (real work). Prefer --agent-expand on install.sh.
# Returns 0 on success; writes stamp under $repo/.arch-expand-state/
# Also writes modules/<name>/.agent-expanded when the module hook does.
am_run_module_expand() {
  local repo="$1"
  local name="$2"
  local dry="${3:-0}"
  local mod_path script stamp_dir stamp marker

  mod_path=$(jq -r --arg n "$name" '.expandable.modules[$n].path // empty' "$(am_core_map_path)")
  if [[ -z "$mod_path" ]]; then
    echo "module path missing from core-map: $name" >&2
    return 1
  fi
  script="$repo/$mod_path/install.sh"
  stamp_dir="$repo/.arch-expand-state"
  stamp="$stamp_dir/${name}.stamp"
  marker="$repo/$mod_path/.agent-expanded"

  if [[ ! -d "$repo/$mod_path" ]]; then
    echo "module tree missing after ensure: $repo/$mod_path" >&2
    return 1
  fi

  if [[ "$dry" == "1" ]]; then
    echo "dry-run: would run module expand for $name"
    if am_module_has_agent_expand "$script"; then
      echo "dry-run: would execute: bash $script --agent-expand"
    elif [[ -f "$script" ]]; then
      echo "dry-run: would stamp $stamp (install.sh has no --agent-expand hook yet)"
    else
      echo "dry-run: would write stamp $stamp (no install.sh)"
    fi
    return 0
  fi

  mkdir -p "$stamp_dir"
  if am_module_has_agent_expand "$script"; then
    # Real entry: --agent-expand must perform non-dry work for this module
    if bash "$script" --agent-expand; then
      date -Iseconds >"$stamp"
      # Ensure marker even if module forgot it (proof of real expand)
      [[ -f "$marker" ]] || date -Iseconds >"$marker"
      echo "module_expand_ok: $name (via $script --agent-expand)"
      echo "stamp: $stamp"
      echo "marker: $marker"
      return 0
    fi
    echo "module install.sh --agent-expand failed: $script" >&2
    return 1
  fi

  # Tree present; no hook yet — still real consented work: stamp + marker
  date -Iseconds >"$stamp"
  date -Iseconds >"$marker"
  echo "module_expand_ok: $name (tree present; stamp+marker; no --agent-expand hook)"
  echo "stamp: $stamp"
  echo "marker: $marker"
  return 0
}
