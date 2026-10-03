---
name: no-rule-one-off
version: 0.1.0
description: >
  A single agent miss may need no new rule. If it was a one-off incident,
  maybe there is nothing to fix in the environment. Talk ~51:30.
---

# no-rule-one-off

> **Load rule:** Pair with `environment-on-repeat`. This skill is the hold branch.

```text
ONE_OFF : a single weird PR or miss
FIX_ENV : only when the pattern repeats across agents
SAMPLE  : human review catches one-offs without new lint
```

**Mission:** Do not amend the kitchen for a single bad dish.

Lauren Tan said that when sampling pull requests, if a bad pattern was a one-off incident, "maybe there's nothing to fix there" (~51:30). Environment changes come when multiple agents repeat the same shortcut (~51:30–52:00) — see `environment-on-repeat`.

Credit Lauren Tan and Matt Pocock.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| Someone wants a new lint after one strange PR | Activate |
| Findings file has a single row on a theme | Activate |
| Same shortcut already appeared across agents | Skip — use `environment-on-repeat` |
| Clear bug with a test already red | Skip — fix the bug |

Slash: `/no-rule-one-off`.

---

## Workflow

1. Count independent occurrences. One agent, one PR, one row → candidate one-off.
2. Check reversibility. If harm is already merged, revert or patch first; still skip new rules if isolated.
3. Ask: would a second agent hit this without the same context? If no, close as one-off.
4. Document the decision in the findings file or review note. No new lint, skill, or type rule.
5. Resample later. If the pattern returns, escalate to `environment-on-repeat`.

### Neighbors

| Need | Load |
|------|------|
| Pattern repeats across agents | `environment-on-repeat` |
| Findings buffer | `findings-first` |
| Layer choice for a real invariant | `trust-stack` |

---

## Emit (required)

```markdown
## No rule (one-off)
| Field | Value |
|-------|--------|
| **occurrences** | 1 \| n |
| **decision** | one-off \| escalate |
| **action** | revert \| patch \| none |
| **new_rule** | none |
| **resample** | when |
```

---

## Done when

- A one-off did not spawn a new permanent rule
- Escalation path to `environment-on-repeat` is named if the pattern returns

## Limitations

- Not permission to ignore a red test.
- Does not block justified fixes to real bugs.
