---
name: kitchen-time
version: 0.2.0
description: >
  Invest before scaling. The low-trust trap is a kitchen that was never set
  up: dull knives, no garlic press. Many pull requests are gardening and
  environment work. No calendar slice is prescribed.
---

# kitchen-time

Stuck micromanaging agents because the kitchen was never set up: dull knives, no garlic press. Many pull requests are gardening and environment work. No calendar slice is assigned. Invest before scaling.

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
4. Count gardening PRs honestly.
5. Re-evaluate trust after the investment lands.

## Emit

```markdown
## Kitchen time
| Field | Value |
|-------|--------|
| **proxy_work** | |
| **investment** | script \| hook \| constraint \| verify |
| **verify** | command or missing |
| **next** | one kitchen edit |
```
