---
description: Add an open task to premflow todo list via real CLI
argument-hint: task title
---

# /task — open work item

Assumes `premflow` is on PATH (system install). If missing → suggest `/init`, then `/init --yes` after consent.

```bash
PF=$(command -v premflow) || { echo "premflow not on PATH — suggest /init"; exit 1; }
$PF task add "$ARGUMENTS"
```

For completion: `$PF task done <n>` after `$PF task list` if needed.
