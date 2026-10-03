---
name: kitchen-time
version: 0.2.0
description: >
  Our adaptation. Lauren Tan described the low-trust trap and dull knives
  (~27:30–29:30) and gardening PRs (~47:00). She did not prescribe a time
  slice.
---

# kitchen-time

**Our adaptation.** Lauren Tan (~27:30–29:30): stuck micromanaging agents because the kitchen was never set up — dull knives, no garlic press. (~47:00): many PRs are gardening and environment work. She did **not** assign a calendar slice. This skill is our prompt to invest before scaling.

## When

| Signal | Action |
|--------|--------|
| You copy agent output by hand every run | Activate |
| Verification always needs you as proxy | Activate |
| Environment is trusted and events are wired | Skip |

## Workflow

1. Name the proxy work you did recently.
2. Pick one investment that removes it: script (`shared-scripts`), event hook (`events-over-timers`), invariant (`trust-stack` / `repeat-or-leave`), or verify skill.
3. Do not open a feature PR until that investment has verify or a findings row.
4. Count gardening PRs honestly (~47:00).
5. Re-evaluate trust after the investment lands.

## Emit

```markdown
## Kitchen time
| Field | Value |
|-------|--------|
| **adaptation** | yes — ours |
| **proxy_work** | |
| **investment** | script \| hook \| constraint \| verify |
| **verify** | command or missing |
| **next** | one kitchen edit |
```
