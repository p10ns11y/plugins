---
name: trust-stack
version: 0.1.0
description: >
  Place one invariant on the earliest layer that can hold it: shape, check,
  watch, skill, then a human guide. Use for /trust-stack, agent trust,
  repeated bad patterns, review load, or before fanning out writers.
  This plugin does not merge.
---

# trust-stack

> **Load rule:** This file owns the layer. Tables live in [references/layers.md](references/layers.md). Open that file only to pick the row. Do not paste the talk.

```text
// Signature
TS    : trust-stack (this skill)
SHAPE : wrong change is hard to represent
CHECK : compiler or static analysis fails the build
WATCH : a bot or a rule flags it; an agent fixes the finding
SKILL : the lesson is written down once, after a real miss
GUIDE : a person still has to read for taste

// Axioms
A1  Earliest layer wins. Do not store an invariant in a person's head if a checker can hold it.
A2  The codebase is the memory. Agents copy what they can see.
A3  Verification means the agent runs the real surface. A claim is not a pass.
A4  One owner per change. Fan out only after one agent is trusted here.
A5  A repeated miss becomes a skill or a check, not only a patch.
A6  This plugin does not merge. Landing stays a human act.
A7  When using Bend, from `bend/`: run `bend guide`; keep rules in `LAWS.bend`; run `bend PROOF.bend` before committing; parallelize independent calls of similar cost. `trust-stack/test/bend-critical.sh` must print "All terms check." If Bend is absent, that proof was not run. A passing proof is the shape layer only. Keep the test, the review, and a person on `guide`. Do not prove `F32`. Do not `@unsafe` past a failed proof.
```

**Mission:** Name the layer that should have caught this, and the one next edit that moves the invariant there.

pstack (`poteto-mode`) is the playbook when it is installed. This skill does not copy it. Credit Lauren Tan, MIT.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| Shipping, review load, "can I trust the agent", fan-out | Activate |
| The same workaround or excuse-comment showed up again | Activate |
| A pull request is about to land | Activate, then stop before merge |
| The invariant is already a failing test or a type | Skip. Run that check. |
| One-file typo with the check already green | Skip |

Slash: `/trust-stack`.

---

## Instructions

1. Name the invariant in one sentence. What must stay true after the agent leaves?
2. Walk [references/layers.md](references/layers.md) from `shape` downward. Stop at the first layer that can hold it.
3. If the answer is `guide`, set hitl. A person is still the checker.
4. If the agent copied a bad pattern, the next edit removes that pattern from the tree. Then add the check or the skill. Do not add a comment that explains the bug away.
5. State the verify command the agent can run. If Bend is installed and the layer is `shape`, the command is `trust-stack/test/bend-critical.sh`. Refuse it when `bunfig.toml` sits beside the proof. If Bend is absent, verify is `missing` and the proof was not run.
6. One owner for this change. Name any collector agents separately. They do not edit it.
7. Hand the card to intelliarch when this skill was loaded as a signal. It does not replace the route.

### Neighbors

| Need | Load |
|------|------|
| Which machine runs the job | `split-machine` |
| The playbook steps | installed pstack, else `pstack-map` |
| A plan that is getting grandiose | `odysseus-navigator` |
| The diff is the proof | `adversarial-audit` |

---

## Emit (required)

```markdown
## Trust
| Field | Value |
|-------|--------|
| **invariant** | |
| **layer** | `shape` · `check` · `watch` · `skill` · `guide` |
| **contagion** | none, or the pattern to delete |
| **verify** | the command, or "missing" |
| **owner** | one |
| **hitl** | none · required (guide, or landing) |
| **next** | one edit that moves the invariant earlier |
```

---

## Done when

- One layer from the closed set
- `guide` did not pretend to be automated
- A repeated pattern has a delete step, not a new excuse
- No merge, no push, no "the agents land it"
- pstack was not copied

## Limitations

- Not a merge bot, a review-bot install, or a Bend compiler.
- A Bend proof is the shape layer. Bend 2 is new, the checker is young, and a green proof can still be wrong.
- Does not score a pull-request count as success.
- Does not claim the talk's production setup. The card is the procedure.
