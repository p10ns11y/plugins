---
description: Run threat-focused security audit (read-only, FSD-safe)
argument-hint: "[global|path|--dry-run|--verbose]"
---

# /arch-audit — threat-focused audit (no gum TUI)

**User surface:** `/arch-audit` · `/arch-audit global` · `/arch-audit .` · `/arch-audit --dry-run`

Prefer **archy** for interactive control plane; this command runs the **quiet audit backend** used by archy’s Audit menu.

## What you get

Threat areas (compact stdout):

| Area | Meaning |
|------|---------|
| malware | rootkit/trojan indicators (rkhunter/unhide; ClamAV only verbose) |
| ports | listening sockets / suspicious exposure |
| supply | pacman + bounded node_modules / osv |
| config | Lynis/perms/users (skips if no sudo) |

Markers: `[ok]` `[!]` `[x]` `[·]` + `## SUMMARY` with exit `0=clean 1=warn 2=fail`.

## Policy

- Read-only (no install).
- FSD may run without extra consent.
- Uses `maintenance/security-audit.sh` from resolved repo when present; else `tinfoil audit`.

## Agent

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?}"
TARGET="${ARGUMENTS:-global}"
"$PLUGIN/bin/am-audit" $TARGET
```

Summarize **real** SUMMARY + FAIL/WARN lines only; do not invent findings. Point operator at report path printed by the script.
