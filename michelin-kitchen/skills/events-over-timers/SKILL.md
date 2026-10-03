---
name: events-over-timers
version: 0.2.0
description: >
  Wire outer-loop subscriptions into the inner loop (~36:30–37:30). Bursts
  go to a coordinator (~43:30–44:30). Ranking timers last and retiring cron
  are ours; she also keeps timer routines (~47:30).
---

# events-over-timers

Lauren Tan: stop ferrying Slack, mail, and bug reports by hand (~35:00–38:00). Wire subscriptions so agents pull context (~36:30–37:30). When many issues arrive at once, a coordinator agent delegates (~43:30–44:30). At ~47:30 she also has timer routines ("I have some routines like that as well"). **Our adaptation:** prefer events first; use a timer only when no event surface exists; retire cron when an event path covers the same signal.

The findings document she describes at ~47:30–48:30 is a code-scanning routine, not burst buffering. Use `findings-first` for that pattern separately.

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
5. When bursts overlap, let a coordinator delegate (~43:30–44:30) and/or buffer in a findings file (`findings-first`).
6. If cron still runs, document why. Retire it when an event path covers the same signal (**our ranking**).

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
