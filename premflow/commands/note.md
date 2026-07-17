---
description: Capture a one-line note into premflow via real CLI
argument-hint: text to remember
---

# /note — dump into premflow

Assumes `premflow` is on PATH (system install). If missing → suggest `/init`, then `/init --yes` after consent.

Run the **real CLI** (never invent timestamps):

```bash
PF=$(command -v premflow) || { echo "premflow not on PATH — suggest /init"; exit 1; }
$PF note "$ARGUMENTS"
```

If `$ARGUMENTS` is empty, ask the user for the note text, then run.

Confirm from stdout (`✓ Note saved`). One idea, one line.
