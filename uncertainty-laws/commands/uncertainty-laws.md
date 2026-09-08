---
description: Run the four uncertainty laws on a foggy decision. Honest answer, including “nothing to do now.”
argument-hint: optional decision / fog description
---

# /uncertainty-laws

Load skill **uncertainty-laws**. Expand `references/four-laws.md` and `references/scenarios.md` only as needed.

`$ARGUMENTS` = the decision or fog. If empty, take the current turn’s risk / money / life fork.

## Immediate actions

1. Name the **one path** decision (not a population average).
2. Run the four laws **in order**: EV → base rates → variance/ruin → Kelly.
3. Emit the required table. If survival fails Law 3, stop — do not “optimize” Law 4.
4. Allowed honest exits: **act sized**, **buy insurance / shrink path**, **Wait**, **Park**, **nothing you can do now**.
5. No PII, employer names, or live debt amounts in the emit.
6. If a mission-map exists for this \(G\), attach `mm_hook`: which node (Do/Risk/Wait/Park) this law-pass governs.

## Emit (required)

```markdown
## Uncertainty-laws
| Field | Value |
|-------|--------|
| **decision** | |
| **Law1 EV** | favour / against / unknown |
| **Law2 base rate** | evidence updates what prior? |
| **Law3 ruin** | can this path kill the game? |
| **Law4 size** | under-Kelly / skip / N/A |
| **honest exit** | act sized · shrink · Wait · Park · nothing-now |
| **next act** | one line or “none” |
| **mm_hook** | mission-map node id/class or none |
```

Credit napkin framing: Venix https://x.com/0xVenix/status/2095614241969520904
