#!/usr/bin/env bash
# Cursor beforeShellExecution tether (eva-emptiness).
# Deny trauma patterns; fail-open if JSON unreadable.
set -euo pipefail

input="$(cat || true)"
command=""
if command -v jq >/dev/null 2>&1; then
  command="$(printf '%s' "$input" | jq -r '.command // .tool_input.command // .toolInput.command // empty' 2>/dev/null || true)"
fi
blob="${command:-$input}"

deny() {
  reason="$1"
  # Cursor: permission deny + messages
  printf '%s\n' "{\"permission\":\"deny\",\"user_message\":\"eva-emptiness tether: ${reason}\",\"agent_message\":\"Blocked by eva-emptiness tether: ${reason}. Use HITL Ask — do not bypass with yolo/always-approve.\"}"
  exit 0
}

case "$blob" in
  *'--always-approve'*|*'--yolo'*|*permission_mode=always-approve*)
    deny "refusing always-approve/yolo (auth event horizon)"
    ;;
esac

# Force HITL Ask (not hard-deny) so an explicit human approval can proceed.
if printf '%s' "$blob" | grep -Eqi 'git[[:space:]]+push[[:space:]]+(-f|--force)'; then
  deny "force-push blocked"
fi
if printf '%s' "$blob" | grep -Eqi '(^|[[:space:];|&])git[[:space:]]+push([[:space:]]|$)'; then
  printf '%s\n' "{\"permission\":\"ask\",\"user_message\":\"eva-emptiness tether: git push requires human Ask (remote mutate)\",\"agent_message\":\"HITL Ask for git push — proceed only after explicit human approval for this remote mutate.\"}"
  exit 0
fi
if printf '%s' "$blob" | grep -Eqi 'git[[:space:]]+reset[[:space:]]+--hard'; then
  deny "git reset --hard blocked"
fi
if printf '%s' "$blob" | grep -Eqi 'rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*|--recursive).*[[:space:]]/($|[[:space:]])'; then
  deny "recursive delete targeting filesystem root blocked"
fi

printf '%s\n' '{"permission":"allow"}'
exit 0
