#!/usr/bin/env bash
# PreToolUse Bash tether for eva-emptiness.
# Explicit deny JSON blocks; fail-open on parse errors (Grok contract).
set -euo pipefail

input="$(cat || true)"
tool_input="$(printf '%s' "$input" | sed -n 's/.*"toolInput"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
# Prefer jq if present (nested JSON); else fall back to raw blob search
if command -v jq >/dev/null 2>&1; then
  tool_input="$(printf '%s' "$input" | jq -r '
    .toolInput // empty
    | if type == "object" then (.command // .cmd // .script // tostring) else tostring end
  ' 2>/dev/null || true)"
fi
blob="${tool_input:-$input}"

deny() {
  reason="$1"
  printf '%s\n' "{\"decision\":\"deny\",\"reason\":\"eva-emptiness tether: ${reason}\"}"
  exit 0
}

# Trauma patterns — authorization / irreversible / auto-anxiety
case "$blob" in
  *'--always-approve'*|*'--yolo'*|*permission_mode=always-approve*|*permission_mode=\"always-approve\"*)
    deny "refusing always-approve/yolo under EVA tether (auth event horizon)"
    ;;
esac

if printf '%s' "$blob" | grep -Eqi '(^|[[:space:];|&])git[[:space:]]+push([[:space:]]|$)'; then
  deny "git push requires human Ask (auth / remote mutate)"
fi
if printf '%s' "$blob" | grep -Eqi 'git[[:space:]]+push[[:space:]]+(-f|--force)'; then
  deny "force-push blocked"
fi
if printf '%s' "$blob" | grep -Eqi 'git[[:space:]]+reset[[:space:]]+--hard'; then
  deny "git reset --hard blocked"
fi
if printf '%s' "$blob" | grep -Eqi 'rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*|--recursive).*[[:space:]]/($|[[:space:]])'; then
  deny "recursive delete targeting filesystem root blocked"
fi

exit 0
