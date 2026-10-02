---
name: concordance
version: 0.1.0
description: >
  Corroborate one closed decision. The decision model proposes a label,
  the LLM confirms a label, and the act is proceed only when they match
  and p_dm >= tau. Use for /concordance, or a closed decision that must
  be corroborated. Hold returns to the router.
---

# concordance

> **Load rule:** This file owns the check. The log line lives in [references/card.md](references/card.md). Open that file only to append one line. Do not paste a vendor writeup into the turn.

```text
// Signature
CC   : concordance (this skill)
DM   : label_dm, the closed label a decision model proposed
LLM  : label_llm, the closed label an LLM confirmed
P    : p_dm, the decision model's number, unscaled
TAU  : tau, the caller's threshold
K    : kappa_window, optional, over recent cases

// Axioms
A1  One pair of labels. A second pair is a second case.
A2  The labels match or they do not. A paraphrase is a miss.
A3  proceed only when agree is yes and p_dm >= tau.
A4  hold is the odd case. intelli-route routes the hold.
A5  tau is the caller's number. This skill does not pick a default.
A6  kappa_window does not change act.
A7  The caller brings both labels. This skill does not call a model vendor.
```

**Mission:** Emit the card. `proceed` only on a real match at or above `tau`. `hold` goes back to the router.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| A closed decision that must be corroborated | Activate |
| Two labels, a `p_dm`, and a `tau` are already on the table | Activate |
| The goal is only which skill to load | Skip. That is intelli-route. |
| The goal is which machine runs the job | Skip. That is split-machine. |
| The goal is which layer holds an invariant | Skip. That is trust-stack. |

Slash: `/concordance`.

---

## Instructions

1. Read `label_dm`, `label_llm`, `p_dm`, and `tau`. Leave a missing input empty. Do not fill it.
2. Set `agree` to `yes` only when both labels are present and the same token. Any other pair is `no`, including a different case or a shorter synonym.
3. Set `act` to `proceed` only when `agree` is `yes` and both numbers are present and `p_dm >= tau`. Do not rescale either number.
4. Every other case is `hold`. That includes a miss, a missing label, a missing number, and a `p_dm` under `tau`.
5. Leave `kappa_window` empty unless the caller supplied a window of recent cases. Then use the kappa in [references/card.md](references/card.md). Do not invent the count.
6. Emit the card. On `hold`, stop. intelli-route routes the hold. This skill does not pick a load.
7. On `proceed`, the card is the result. This skill still does not pick a load.
8. Append one log line only when the caller named a path.

### Neighbors

| Need | Who owns it |
|------|-------------|
| Which machine runs the job | `split-machine`. A system-one label may arrive as `label_dm`. |
| Which layer holds the invariant | `trust-stack`. This check is one it can point at. |
| Which skills load, including after `hold` | `intelli-route`. |

---

## Emit (required)

```markdown
## Concordance
| Field | Value |
|-------|--------|
| **label_dm** | |
| **label_llm** | |
| **agree** | yes \| no |
| **p_dm** | |
| **kappa_window** | optional, over recent cases |
| **act** | proceed \| hold |
```

---

## Examples

User: decision model `ship`, LLM `ship`, `p_dm` 0.91, `tau` 0.8.
Agent: `agree` yes, `act` proceed.

User: decision model `ship`, LLM `hold`, `p_dm` 0.95, `tau` 0.8.
Agent: `agree` no, `act` hold. intelli-route routes the hold.

User: both labels `ship`, `p_dm` 0.4, `tau` 0.8.
Agent: `agree` yes, `act` hold.

## Done when

- The card has all six fields
- `proceed` only when agree is yes and p_dm >= tau
- `hold` did not pick a skill
- `kappa_window` is empty when no window was supplied
- No claim that this plugin called a model vendor

## Limitations

- Not a router, a judge model, or a stats package.
- Does not calibrate `p_dm` and does not choose `tau`.
- A match under `tau` stays `hold` even though `agree` is `yes`.
