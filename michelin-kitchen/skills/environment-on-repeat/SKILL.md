---
name: environment-on-repeat
version: 0.1.0
description: >
  Change the environment only when several agents repeat the same shortcut or
  workaround. Course-correct skills, constraints, and lint — not a single
  agent instance. Talk ~51:30–52:00.
---

# environment-on-repeat

> **Load rule:** Pair with `no-rule-one-off` for the first occurrence. Use `trust-stack` to pick the earliest layer.

```text
REPEAT   : same shortcut across multiple agents or PRs
ENV      : skills, lint, types, scripts — not a lecture to one chat
SAMPLE   : review finds the pattern; environment fix prevents recurrence
```

**Mission:** Fix the kitchen when the same mistake keeps being cooked.

Lauren Tan said that when multiple agents share the same issue or workaround, that is a sign to amend the kitchen: skills, constraints, lint, type systems (~51:30–52:00). A one-off does not qualify (~51:30) — see `no-rule-one-off`.

Credit Lauren Tan and Matt Pocock.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| Findings file shows the same theme across rows or agents | Activate |
| Review sample shows the same excuse-comment or workaround | Activate |
| Single odd PR with no echo | Skip — `no-rule-one-off` |
| Invariant already has a failing check | Skip — run the check |

Slash: `/environment-on-repeat`.

---

## Workflow

1. Quote the repeated pattern in one sentence. Link at least two independent occurrences (PRs, agents, or findings rows).
2. Load `trust-stack`. Walk layers from `shape` downward. Pick the earliest layer that can hold the invariant.
3. Delete the contagious pattern from the tree — workaround, excuse comment, or copied bad idiom.
4. Add the hold at that layer: type, lint, script (`shared-scripts`), or skill edit (`workflow-skills`).
5. Verify with the real command. One owner re-runs the sample that found the pattern.
6. If the pattern was a false alarm after two looks, downgrade to `no-rule-one-off`.

### Neighbors

| Need | Load |
|------|------|
| First occurrence only | `no-rule-one-off` |
| Earliest layer table | `trust-stack` |
| Mechanical enforcement | `shared-scripts` |

---

## Emit (required)

```markdown
## Environment on repeat
| Field | Value |
|-------|--------|
| **pattern** | |
| **occurrences** | n (linked) |
| **layer** | shape \| check \| watch \| skill \| guide |
| **deleted** | contagious artifact |
| **verify** | command |
| **next** | one environment edit |
```

---

## Done when

- At least two independent occurrences are cited
- The fix moves an invariant earlier, not a chat scolding
- One-off path was considered

## Limitations

- Does not merge pull requests.
- Does not replace `trust-stack`; it applies the same layer walk after repeat is proven.
