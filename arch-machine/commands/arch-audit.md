---
description: Run tinfoil security audit (read-only, FSD-safe)
argument-hint: "[path]"
---

# /arch-audit — sentinel audit without TUI

**User surface:** `/arch-audit` · `/arch-audit .` · `/arch-audit /path`  
Prefer this over `tinfoil tui`.

## Policy

- Read-only audit via `tinfoil audit`.
- If tinfoil missing → `/arch-status` / `/arch-init` first.
- FSD may run without extra consent.

## Agent

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?}"
TARGET="${ARGUMENTS:-.}"
"$PLUGIN/bin/am-audit" $TARGET
```

Summarize real audit output; do not invent findings.
