---
name: findings-first
version: 0.2.0
description: >
  Append findings to a document and review every few days for patterns.
  Write the file before pinging anyone. A notification is only a pointer
  to the file.
---

# findings-first

Append observations to a document. Review every few days. Cluster before fixing. Write to the file before pinging anyone. If someone must know, the ping is only a pointer to the file.

## When

| Signal | Action |
|--------|--------|
| A scout or linter found something worth tracking | Activate |
| Someone is about to ping a human with a raw log | Activate |
| One obvious fix already verified green | Skip |

## Workflow

1. Choose or create the findings file for this theme.
2. Append one row per observation: what, where, when, evidence. No fix PR yet.
3. If a human or coordinator must know: path + count + date range. Not the raw dump.
4. On your review cadence, read the file. Cluster rows.
5. One pattern → one fix proposal. Scattered rows → `repeat-or-leave`.
6. After clustering: spawn fix work or open one PR per theme.

Load `events-over-timers` when triggers are noisy. Load `pulse-memory` for long-lived tagged memory.

## Emit

```markdown
## Findings-first
| Field | Value |
|-------|--------|
| **file** | path |
| **rows_added** | n |
| **pinged** | yes \| no |
| **pointer** | path or none |
| **clusters** | themes or "too early" |
| **next** | review \| one fix PR \| wait |
```
