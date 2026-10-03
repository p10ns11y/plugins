---
name: michelin-kitchen
version: 0.1.0
description: >
  Index of eight kitchen habits from Lauren Tan and Matt Pocock's talk. Load
  one habit skill, not all eight. Two habits are house adaptations.
---

# michelin-kitchen

> **Load rule:** Open one habit skill. This file is the index only.

| Habit | Skill | Source |
|---|---|---|
| Shared deterministic scripts | `shared-scripts` | Talk |
| Findings file before pings | `findings-first` | Talk + house note |
| Events over timers | `events-over-timers` | Talk |
| Workflow-shaped skills | `workflow-skills` | Talk |
| No rule for a one-off | `no-rule-one-off` | Talk |
| Environment fix on repeat | `environment-on-repeat` | Talk |
| Verifier count vs risk | `scaled-verifiers` | **House adaptation** |
| Invest in the kitchen | `kitchen-time` | **House adaptation** |

README timestamps and overlap: [../../README.md](../../README.md).

Credit Lauren Tan and Matt Pocock. pstack is Lauren Tan's Cursor plugin; this repo ships pstack-map only.

---

## Workflow

1. Read the user goal. Match one row in the table.
2. Load only that habit's `SKILL.md`. Do not paste all eight.
3. Follow that skill's workflow and Emit block.
4. If two habits match, prefer the more specific (e.g. `findings-first` before `events-over-timers` when PRs would precede a file).

Slash: use the habit command (`/findings-first`, etc.) when known.
