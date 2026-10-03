---
name: events-over-timers
version: 0.1.0
description: >
  Prefer reacting to a real event (webhook, CI result, mail, channel message)
  over polling on a schedule. Connect the outer loop to the inner loop. Use a
  findings file as a buffer when bursts arrive. Talk ~36:00–39:00, ~48:00.
---

# events-over-timers

> **Load rule:** This file owns trigger choice. Use `findings-first` when events arrive faster than fixes.

```text
OUTER : Slack, mail, CI, bug tracker — context outside the repo
INNER : agents working the code toward an intent
EVENT : webhook, subscription, CI completion, message arrival
TIMER : cron or poll — fallback only when no event surface exists
```

**Mission:** Stop being the proxy between outer-loop noise and inner-loop work.

Lauren Tan described being the bottleneck ferrying bug reports from Slack or mail into agent chats (~36:00–39:00). She wires subscriptions so agents pull context themselves (~37:30–38:30). When bursts arrive, a findings document buffers before execution (~48:00–50:00).

Credit Lauren Tan and Matt Pocock.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| A human copies context from chat or mail into every agent run | Activate |
| Work is on a cron but a webhook or CI event exists | Activate |
| Burst of similar reports risks duplicate fix PRs | Activate; pair `findings-first` |
| No event surface and low stakes | Timer is acceptable; document why |

Slash: `/events-over-timers`.

---

## Workflow

1. Name the outer-loop source. Where does context appear before an agent sees it?
2. List what you manually copy each time. That list is the subscription spec.
3. Prefer an event hook: channel subscription, CI result, inbound mail rule, webhook. Host names as aliases only (`laptop-1`, `mac-mini`).
4. Wire the hook to the inner loop: message to a project, file drop, or queue row — not straight to ten parallel fixers when themes may overlap.
5. When events burst, append to a findings file first (`findings-first`). Delegate fix work after clustering.
6. Retire the timer if an event path now covers the same signal.

### Neighbors

| Need | Load |
|------|------|
| Findings file before pings or PRs | `findings-first` |
| Route which skill runs on the event | `intelli-route` |
| Verification after the inner loop picks up work | `trust-stack` |

---

## Emit (required)

```markdown
## Events over timers
| Field | Value |
|-------|--------|
| **outer_source** | |
| **event_hook** | what fires |
| **inner_handoff** | |
| **buffer** | findings file or none |
| **timer_retired** | yes \| no \| n/a |
| **next** | one wiring step |
```

---

## Done when

- A real event carries context the agent used to need from a human
- Bursts use a findings buffer when themes may overlap
- Cron is justified or removed

## Limitations

- Does not install connectors; names the shape only.
- Does not replace `intelli-route` for skill choice.
