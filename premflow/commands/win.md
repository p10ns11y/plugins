---
description: Log a win into premflow via real CLI
argument-hint: what went well
---

# /win — celebrate into the ledger

Assumes `premflow` is on PATH (system install). If missing → run `/init`.

```bash
PF=$(command -v premflow) || { echo "premflow not on PATH — run /init"; exit 1; }
$PF win "$ARGUMENTS"
```

Confirm `✓ Win logged`. Do not hand-edit `log.txt`.
