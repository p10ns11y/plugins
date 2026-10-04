---
name: events-over-timers
version: 0.2.0
description: >
  Wire outer-loop subscriptions into the inner loop. Send bursts to a
  coordinator. Prefer events. Use a timer only when no event surface exists.
  Retire cron when an event path covers the same signal.
---

# events-over-timers

Stop ferrying Slack, mail, and bug reports by hand. Wire subscriptions so agents pull context. When many issues arrive at once, a coordinator agent delegates. Timer routines can still exist. Prefer events first; use a timer only when no event surface exists; retire cron when an event path covers the same signal.

A code-scanning findings routine is not burst buffering. Use `findings-first` for that pattern separately.

## When

| Signal | Action |
|--------|--------|
| A human copies chat or mail into every agent run | Activate |
| Cron polls a channel that could subscribe | Activate |
| Burst of similar reports may duplicate work | Activate; pair coordinator + `findings-first` |
| No event surface and low stakes | Timer acceptable; say why |

## Workflow

1. Name the outer-loop source.
2. List what you copy manually each time. That is the subscription spec.
3. Prefer an event hook: channel subscription, CI result, mail rule, webhook.
4. Hand off to the inner loop: project message, queue row, or coordinator — not ten parallel fixers on overlapping themes.
5. When bursts overlap, let a coordinator delegate and/or buffer in a findings file (`findings-first`).
6. If cron still runs, document why. Retire it when an event path covers the same signal.

Load `intelli-route` to pick the inner-loop skill. Load `trust-stack` for verify after pickup.

## Emit

```markdown
## Events over timers
| Field | Value |
|-------|--------|
| **outer_source** | |
| **event_hook** | what fires |
| **inner_handoff** | coordinator \| project \| queue |
| **timer** | fallback \| retired \| only option |
| **next** | one wiring step |
```
