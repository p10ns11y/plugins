# michelin-kitchen

Eight habits for running agent work like a professional kitchen. Grounded in a conversation between **Lauren Tan** and **Matt Pocock** about scaling quality, verification, and trust with agents.

Pick the habits you need. You do not have to install the whole set — the talk's own metaphor is a chef who brings their own knives to a new restaurant (~1:02:30).

## Caveats from the talk

- Lauren Tan: she does not want to sell this as something you can just do easily by using pstack (~52:30). **pstack** is [Lauren Tan's Cursor plugin](https://github.com/cursor/plugins/tree/main/pstack) (poteto, MIT). This repo ships **pstack-map**, which maps pstack onto house skills when it is installed. Neither plugin promises her production volume.
- Own your knives (~1:02:30): combine habits with your transcripts, lint, and verify paths. Everyone's kitchen looks different.

## Habits

| Skill | Source | Talk (approx.) |
|---|---|---|
| [shared-scripts](skills/shared-scripts/SKILL.md) | Lauren Tan | ~22:00–25:00 — extract deterministic work into scripts; agents stopped rebuilding glue |
| [findings-first](skills/findings-first/SKILL.md) | Lauren Tan + house note | ~49:00 — append to a document before fixing; review for patterns. On 3 Oct 2026, three draft PRs before a findings file forced a human "pick one" question |
| [events-over-timers](skills/events-over-timers/SKILL.md) | Lauren Tan | ~36:00–39:00, ~48:00 — outer-loop events into the inner loop; buffer bursts in a findings file |
| [workflow-skills](skills/workflow-skills/SKILL.md) | Lauren Tan | ~62:00–65:30 — skills as workflows, not command dumps |
| [no-rule-one-off](skills/no-rule-one-off/SKILL.md) | Lauren Tan | ~51:30 — "maybe there's nothing to fix there" for a one-off |
| [environment-on-repeat](skills/environment-on-repeat/SKILL.md) | Lauren Tan | ~51:30–52:00 — amend the kitchen when multiple agents repeat the same shortcut |
| [scaled-verifiers](skills/scaled-verifiers/SKILL.md) | **House adaptation** | ~54:00–55:00 — she said you might use one verifier instead of ten; ~57:00–1:00:30 — no settled answer on irreversible one-way doors. The risk ladder is ours |
| [kitchen-time](skills/kitchen-time/SKILL.md) | **House adaptation** | ~27:30–29:30 — low-trust trap and dull knives; ~47:00 — gardening PRs. She did not prescribe a calendar time slice. The "invest in the kitchen" prompt is ours |

Illustration for `shared-scripts`: [examples/posting-check/README.md](examples/posting-check/README.md) (job-posting open/closed checker, host-neutral).

## Overlap with other plugins

| Plugin | Use instead of duplicating |
|---|---|
| `trust-stack` | Earliest layer for an invariant (`environment-on-repeat`) |
| `intelli-route` | Route a goal; outer-loop handoff (`events-over-timers`) |
| `pulse-memory` | Tagged sparse memory vs transcript dumps (`findings-first`) |
| `premflow` | Capture after a findings review |
| `mission-map` | When the queue needs a map, not a script |
| `pstack-map` | Playbook map when pstack is installed |

## Install

```bash
grok plugin install ./michelin-kitchen --trust
```

Slash commands: `/shared-scripts`, `/findings-first`, `/events-over-timers`, `/workflow-skills`, `/no-rule-one-off`, `/environment-on-repeat`, `/scaled-verifiers`, `/kitchen-time`.

## Tests

```bash
./michelin-kitchen/test/test-thin.sh
```

Eval dataset: [skills/michelin-kitchen/evals/evals.json](skills/michelin-kitchen/evals/evals.json).

Talk credit: [NOTICE.md](NOTICE.md).
