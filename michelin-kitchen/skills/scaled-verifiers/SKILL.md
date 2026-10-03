---
name: scaled-verifiers
version: 0.2.0
description: >
  Our adaptation. Lauren Tan: sample instead of tasting every dish
  (~49:30–50:00); tune to one verifier instead of ten (~53:30); one-way
  doors depend on how verifiable the domain is (~56:30–57:00).
---

# scaled-verifiers

**Our adaptation.** Lauren Tan: you cannot taste every dish at scale (~49:30–50:00); "instead of like 10 verifier agents, you might do like one" (~53:30). On irreversible work she had no general recipe — it depends on whether agents can truly verify the domain (~56:30–57:00). The risk ladder below is ours.

## When

| Signal | Action |
|--------|--------|
| Full autopilot runs many verifiers on every small PR | Activate |
| Irreversible or legally sensitive work | Activate; bias to human review |
| Trivial change with checks already green | Skip |

## Workflow

1. Classify reversibility: two-way vs one-way. One-way with low verifiability → human review.
2. Classify verifiability: can an agent run the real surface and get a decisive pass?
3. Pick verifier count: self-verify when cheap to revert; one independent verifier when medium; more only when checks are cheap and stakes high (~53:30).
4. Name verify commands. Independent means fresh context, not the same chat re-reading itself.
5. Sample merged work on a schedule you choose. Repeated shortcut → `repeat-or-leave`.

## Emit

```markdown
## Scaled verifiers
| Field | Value |
|-------|--------|
| **adaptation** | yes — ours |
| **reversibility** | two-way \| one-way \| unclear |
| **verifiability** | high \| partial \| low |
| **verifier_count** | n |
| **verify_commands** | |
| **human_review** | required \| optional |
| **next** | one tuning step |
```
