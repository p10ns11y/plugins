---
description: Capture a one-line note into premflow log via real CLI
argument-hint: text to remember
---

# /note — dump into premflow

Run the **real CLI** (never invent timestamps):

```bash
PF=$(command -v premflow || echo "$HOME/Work/personal/premflow/build/premflow")
$PF note "$ARGUMENTS"
```

If `$ARGUMENTS` is empty, ask the user for the note text, then run.

Confirm from stdout (`✓ Note saved`). One idea, one line.
