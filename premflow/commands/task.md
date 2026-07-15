---
description: Add an open task to premflow todo list via real CLI
argument-hint: task title
---

# /task — open work item

```bash
PF=$(command -v premflow || echo "$HOME/Work/personal/premflow/build/premflow")
$PF task add "$ARGUMENTS"
```

For completion: `$PF task done <n>` after `$PF task list` if needed.
