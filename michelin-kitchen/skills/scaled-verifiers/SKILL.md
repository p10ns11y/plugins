---
name: scaled-verifiers
version: 0.2.0
description: >
  Sample instead of checking every change. Tune toward one verifier instead
  of ten. One-way doors depend on how verifiable the domain is.
---

# scaled-verifiers

You cannot taste every dish at scale. Use one verifier instead of ten. Irreversible work has no general recipe; it depends on whether an agent can truly verify the domain.

## When

| Signal | Action |
|--------|--------|
| Full autopilot runs many verifiers on every small PR | Activate |
| Irreversible or legally sensitive work | Activate; bias to human review |
| Trivial change with checks already green | Skip |

## Workflow

1. Classify reversibility: two-way vs one-way. One-way with low verifiability → human review.
2. Classify verifiability: can an agent run the real surface and get a decisive pass?
3. Pick verifier count: self-verify when cheap to revert; one independent verifier when medium; more only when checks are cheap and stakes are high.
4. Name verify commands. Independent means fresh context, not the same chat re-reading itself.
5. Sample merged work on a schedule you choose. Repeated shortcut → `repeat-or-leave`.

## Emit

```markdown
## Scaled verifiers
| Field | Value |
|-------|--------|
| **reversibility** | two-way \| one-way \| unclear |
| **verifiability** | high \| partial \| low |
| **verifier_count** | n |
| **verify_commands** | |
| **human_review** | required \| optional |
| **next** | one tuning step |
```
