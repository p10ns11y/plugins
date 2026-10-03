---
name: scaled-verifiers
version: 0.1.0
description: >
  House adaptation: scale independent verification with risk. Lauren Tan said
  you might use one verifier instead of ten (~54:00–55:00) and had no firm
  answer on irreversible one-way doors (~57:00–1:00:30). Not a talk quote.
---

# scaled-verifiers

> **Load rule:** This habit is a **house adaptation**. Lauren Tan described tuning verifier count and sampling instead of tasting every dish (~54:00–55:00). She did not prescribe a risk ladder. This skill is our compression of that idea.

```text
ADAPTATION : not a direct quote from the talk
SAMPLE     : review some outputs, not every one, when the kitchen is trusted
TUNE       : fewer verifiers when cheap to revert; more when stakes rise
ONE_WAY    : Lauren Tan had no settled answer — default to human review
```

**Mission:** Match verification effort to how hard reversal is and how verifiable the domain is.

Credit Lauren Tan and Matt Pocock for the underlying sampling and verifier-count ideas. This ladder is ours.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| Full autopilot runs ten verifier agents on every small PR | Activate |
| A two-way-door change ships with zero verification | Activate |
| Irreversible or legally sensitive work | Activate; bias to `guide` in `trust-stack` |
| Trivial doc fix with checks already green | Skip |

Slash: `/scaled-verifiers`.

---

## Workflow

1. Classify reversibility: two-way (revert is cheap) vs one-way (data loss, legal, safety). On one-way, Lauren Tan did not offer a general recipe (~57:00–1:00:30) — require human review unless domain verification is genuinely strong.
2. Classify verifiability: can an agent run the real surface and get a decisive pass? If not, do not scale verifiers up; scale humans up.
3. Pick a verifier count: self-verify for low stakes; one independent verifier for medium; more only when independent checks are cheap and stakes are high. Her example: "instead of like 10 verifier agents, you might do like one" (~54:00–55:00).
4. Name the verify commands. Independent means fresh context or a different skill, not the same chat re-reading its own summary.
5. Sample merged work on a schedule you choose. Course-correct the environment when the sample shows a repeated shortcut (`environment-on-repeat`).

### Neighbors

| Need | Load |
|------|------|
| Earliest layer for an invariant | `trust-stack` |
| Deterministic verify scripts | `shared-scripts` |
| One-off miss may need no new rule | `no-rule-one-off` |

---

## Emit (required)

```markdown
## Scaled verifiers
| Field | Value |
|-------|--------|
| **adaptation** | yes — house habit |
| **reversibility** | two-way \| one-way \| unclear |
| **verifiability** | high \| partial \| low |
| **verifier_count** | n |
| **verify_commands** | |
| **human_review** | required \| optional |
| **next** | one tuning step |
```

---

## Done when

- Verifier count is stated and tied to stakes
- One-way work does not rely on "merge and hope"
- The card says this is a house adaptation

## Limitations

- Not Lauren Tan's risk formula; a local heuristic only.
- Does not merge pull requests.
