---
name: repeat-or-leave
version: 0.2.0
description: >
  One-off miss: maybe nothing to fix (~51:30). Same shortcut across several
  agents: amend the kitchen (~51:30–52:00). Use trust-stack for the layer.
---

# repeat-or-leave

Lauren Tan (~51:30–52:00): when sampling pull requests, a one-off bad pattern may mean "maybe there's nothing to fix there." When multiple agents repeat the same shortcut, amend skills, constraints, and lint.

## When

| Signal | Action |
|--------|--------|
| Someone wants a new lint after one strange PR | Activate |
| Findings show the same theme across rows or agents | Activate |
| Clear bug with a test already red | Skip — fix the bug |

## Workflow

1. Count independent occurrences (PRs, agents, findings rows).
2. **One occurrence:** revert or patch if needed; document as one-off; no new lint or skill rule; resample later.
3. **Two or more:** quote the pattern; load `trust-stack` and pick the earliest layer that can hold the invariant (do not copy its layer table here).
4. Delete the contagious artifact — workaround, excuse comment, copied idiom.
5. Add the hold at that layer: type, lint, script (`shared-scripts`), or skill edit (`workflow-skills`).
6. Verify with the real command. One owner re-runs the sample that found the pattern.

## Emit

```markdown
## Repeat or leave
| Field | Value |
|-------|--------|
| **occurrences** | n |
| **decision** | leave \| fix environment |
| **pattern** | sentence or none |
| **trust_stack** | layer name from trust-stack |
| **verify** | command |
| **next** | one edit |
```
