---
name: kitchen-time
version: 0.1.0
description: >
  House adaptation: make room to improve the environment when stuck
  micromanaging agents. Lauren Tan described the low-trust trap and sharpening
  knives (~27:30–29:30) but did not prescribe a time slice. Not a talk quote.
---

# kitchen-time

> **Load rule:** This habit is a **house adaptation**. Lauren Tan described engineers stuck micromanaging because they never invested in tools, constraints, and verification (~27:30–29:30). She compared dull knives and a garlic press (~29:00). She did **not** assign a calendar slice. This skill is our reminder to invest before scaling.

```text
ADAPTATION : not a direct quote from the talk
LOW_TRUST  : micromanage loop leaves no room to improve the kitchen
INVEST     : scripts, lint, types, verification skills, findings paths
GARDENING  : many PRs are environment work (~47:00) — that is legitimate
```

**Mission:** When you are the meat proxy, spend the next cycle on the kitchen, not another manual pass.

Credit Lauren Tan and Matt Pocock for the trap and tooling metaphor. The "make room" prompt is ours.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| You copy agent output by hand every run | Activate |
| Verification always needs you as proxy | Activate |
| Scaling agents is blocked by missing scripts or hooks | Activate |
| Environment is trusted and events are wired | Skip |

Slash: `/kitchen-time`.

---

## Workflow

1. Name the proxy work you did in the last day. What did the agent need you for?
2. Pick one kitchen investment that removes that proxy: script (`shared-scripts`), event hook (`events-over-timers`), constraint (`trust-stack` / `environment-on-repeat`), or verify skill.
3. Do not open a feature PR until that investment has a verify path or a findings row.
4. Track gardening work honestly (~47:00): refactors, lint, tooling PRs count as kitchen work.
5. Re-evaluate trust after the investment lands. If still proxying, repeat with the next bottleneck.

### Neighbors

| Need | Load |
|------|------|
| Deterministic scripts | `shared-scripts` |
| Event wiring | `events-over-timers` |
| Layer for an invariant | `trust-stack` |
| Repeated shortcut across agents | `environment-on-repeat` |

---

## Emit (required)

```markdown
## Kitchen time
| Field | Value |
|-------|--------|
| **adaptation** | yes — house habit |
| **proxy_work** | what you carried by hand |
| **investment** | script \| hook \| constraint \| verify |
| **verify** | command or missing |
| **next** | one kitchen PR or edit |
```

---

## Done when

- The card states this is a house adaptation
- One concrete investment is named
- No invented calendar time slice

## Limitations

- Not a time-management system.
- Does not promise pstack or any plugin will get you to thousands of PRs.
