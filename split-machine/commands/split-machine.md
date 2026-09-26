---
description: Place one job on Earth, orbit, a GPU, a BQP slice, a typed decision, or prose. Low confidence does not automate.
argument-hint: the job, or a claim about which machine should do it
---

# /split-machine

Load skill **split-machine**. Open `references/placement.md` only to pick one row.

`$ARGUMENTS` is the job. If it is empty, use the current turn.

## Immediate actions

1. If two jobs are glued together, split them. Place each.
2. Pick one substrate: `earth-qpu`, `orbit-link`, `gpu-factory`, `bqp-slice`, `system-one`, or `system-two`.
3. Name the act in that row's verbs. You evolve a state under a Hamiltonian. You do not evolve the Hamiltonian.
4. Set confidence `high`, `med`, or `low`. On `low`, emit the table and stop.
5. Refuse NISQ-as-inference, a QPU doing dense matmul, and a fridge in orbit.

## Emit (required)

```markdown
## Split
| Field | Value |
|-------|--------|
| **job** | |
| **substrate** | |
| **act** | |
| **confidence** | high · med · low |
| **refused** | |
| **wording** | |
| **next** | |
```

Credit the placement posts and the System One shape named in `NOTICE.md`. Do not claim a vendor call.
