---
description: Read-only arch-machine status (archy + tinfoil + core paths; FSD-safe)
argument-hint: "[map]"
---

# /arch-status — thin core + control plane health

**User surface:** `/arch-status` · `/arch-status map`  
Agent-internal only: `am-status`, `am-map` — do not tell the user to run those names.

## Policy

- Always **read-only** (no install, no expand).
- FSD/unsupervised may run this without asking.

## Agent implementation

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set}"
if echo "$ARGUMENTS" | grep -qw map; then
  "$PLUGIN/bin/am-map"
else
  "$PLUGIN/bin/am-status"
fi
```

Report: **archy** binary/source?, tinfoil on PATH?, repo root, audit script, core tier.  
If incomplete, suggest `/arch-init` then `/arch-init --yes` after consent; for UI suggest `/arch-control` or build archy.
