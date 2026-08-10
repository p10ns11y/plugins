# eva-tether-shell.inc — portable shell fallback for EVA tether (POSIX).
# Sourced by entry hooks when the C binary is unavailable.
# No eval. No unquoted expansions in command positions.
# shellcheck shell=sh

# Caller must set: EVA_TETHER_MODE=grok|cursor
# Reads stdin; prints decision JSON (mode-specific). Always exit 0 (fail-open).

eva_tether_shell_main() {
  # Local vars: prefer typeset in zsh, fall through for POSIX.
  # shellcheck disable=SC2039
  input=""
  blob=""
  tool_input=""

  input=$(cat 2>/dev/null || true)

  tool_input=$(eva_tether_extract_field "$input" "$EVA_TETHER_MODE")
  if [ -n "$tool_input" ]; then
    blob=$tool_input
  else
    blob=$input
  fi

  if eva_tether_match_always_approve "$blob"; then
    eva_tether_emit_deny "refusing always-approve/yolo under EVA tether (auth event horizon)"
    return 0
  fi
  if eva_tether_match_force_push "$blob"; then
    eva_tether_emit_deny "force-push blocked"
    return 0
  fi
  if eva_tether_match_git_push "$blob"; then
    if [ "$EVA_TETHER_MODE" = "cursor" ]; then
      eva_tether_emit_ask "git push requires human Ask (auth / remote mutate)"
    else
      eva_tether_emit_deny "git push requires human Ask (auth / remote mutate)"
    fi
    return 0
  fi
  if eva_tether_match_reset_hard "$blob"; then
    eva_tether_emit_deny "git reset --hard blocked"
    return 0
  fi
  if eva_tether_match_rm_root "$blob"; then
    eva_tether_emit_deny "recursive delete targeting filesystem root blocked"
    return 0
  fi

  eva_tether_emit_allow
  return 0
}

# Extract command-like field without jq (no network, no eval).
eva_tether_extract_field() {
  _raw="$1"
  _mode="$2"
  _val=""

  if [ "$_mode" = "cursor" ]; then
    _val=$(eva_tether_json_string "$_raw" "command")
  else
    _val=$(eva_tether_json_string "$_raw" "toolInput")
    if [ -z "$_val" ]; then
      _val=$(eva_tether_json_string "$_raw" "command")
    fi
    if [ -z "$_val" ]; then
      _val=$(eva_tether_json_string "$_raw" "cmd")
    fi
    if [ -z "$_val" ]; then
      _val=$(eva_tether_json_string "$_raw" "script")
    fi
  fi
  # Prefer jq only for nested object toolInput when present (optional).
  if [ -z "$_val" ] && command -v jq >/dev/null 2>&1; then
    if [ "$_mode" = "cursor" ]; then
      _val=$(printf '%s' "$_raw" | jq -r \
        '.command // .tool_input.command // .toolInput.command // empty' \
        2>/dev/null || true)
    else
      _val=$(printf '%s' "$_raw" | jq -r '
        .toolInput // empty
        | if type == "object" then (.command // .cmd // .script // tostring) else tostring end
      ' 2>/dev/null || true)
    fi
  fi
  printf '%s' "$_val"
}

# Naive JSON string field extractor: "key" : "value"
# Key is restricted to fixed caller strings (not raw user input as sed code).
eva_tether_json_string() {
  _raw="$1"
  _key="$2"
  case "$_key" in
    command|toolInput|cmd|script) ;;
    *) return 0 ;;
  esac
  # sed: portable enough; fail closed to empty on mess.
  printf '%s' "$_raw" | sed -n \
    "s/.*\"${_key}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" \
    2>/dev/null | head -n 1
}

eva_tether_match_always_approve() {
  case "$1" in
    *'--always-approve'*|*'--yolo'*|*permission_mode=always-approve*|*permission_mode=\"always-approve\"*)
      return 0
      ;;
  esac
  return 1
}

# Force-push: git … push … (-f|--force|--force-with-lease)
eva_tether_match_force_push() {
  printf '%s' "$1" | grep -Eq \
    '(^|[[:space:];|&])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$).*(-f|--force|--force-with-lease)([[:space:]]|$)' \
    2>/dev/null
}

# Ordinary git push (word-ish boundary).
eva_tether_match_git_push() {
  printf '%s' "$1" | grep -Eq \
    '(^|[[:space:];|&])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)' \
    2>/dev/null
}

eva_tether_match_reset_hard() {
  printf '%s' "$1" | grep -Eq \
    '(^|[[:space:];|&])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+reset([[:space:]].*)?--hard([[:space:]]|$)' \
    2>/dev/null
}

eva_tether_match_rm_root() {
  printf '%s' "$1" | grep -Eq \
    '(^|[[:space:];|&])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive).*[[:space:]]/($|[[:space:]]|\*)' \
    2>/dev/null
}

eva_tether_json_escape() {
  # Minimal escape for " and \ and newlines in reason text (fixed patterns only).
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/'"$(printf '\n')"'/\\n/g' 2>/dev/null
}

eva_tether_emit_deny() {
  _reason="$1"
  _full="eva-emptiness tether: ${_reason}"
  _esc=$(eva_tether_json_escape "$_full")
  if [ "$EVA_TETHER_MODE" = "cursor" ]; then
    _agent="Blocked by eva-emptiness tether: ${_reason}. Use HITL Ask — do not bypass with yolo/always-approve."
    _aesc=$(eva_tether_json_escape "$_agent")
    printf '%s\n' "{\"permission\":\"deny\",\"user_message\":\"${_esc}\",\"agent_message\":\"${_aesc}\"}"
  else
    printf '%s\n' "{\"decision\":\"deny\",\"reason\":\"${_esc}\"}"
  fi
}

eva_tether_emit_ask() {
  _reason="$1"
  _full="eva-emptiness tether: ${_reason}"
  _esc=$(eva_tether_json_escape "$_full")
  _agent="HITL Ask for git push — proceed only after explicit human approval for this remote mutate."
  _aesc=$(eva_tether_json_escape "$_agent")
  printf '%s\n' "{\"permission\":\"ask\",\"user_message\":\"${_esc}\",\"agent_message\":\"${_aesc}\"}"
}

eva_tether_emit_allow() {
  if [ "$EVA_TETHER_MODE" = "cursor" ]; then
    printf '%s\n' '{"permission":"allow"}'
  fi
  # Grok allow: empty body, exit 0
}
