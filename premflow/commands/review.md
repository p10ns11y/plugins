---
description: Run premflow smart daily review (non-blocking)
---

# /review — evening signal

```bash
PF=$(command -v premflow || echo "$HOME/Work/personal/premflow/build/premflow")
$PF review
# optional: $PF review --full
# optional: $PF stats
```

Summarize for the user from real stdout. Do not invent wins/tasks.
