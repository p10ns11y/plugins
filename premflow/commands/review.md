---
description: Run premflow smart daily review (non-blocking)
---

# /review — evening signal

Assumes `premflow` is on PATH (system install). If missing → suggest `/init`, then `/init --yes` after consent.

```bash
PF=$(command -v premflow) || { echo "premflow not on PATH — suggest /init"; exit 1; }
$PF review
# optional: $PF review --full
# optional: $PF stats
```

Summarize for the user from real stdout. Do not invent wins/tasks.
