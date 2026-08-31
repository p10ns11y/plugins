---
description: Audit layout-content-view stability (graph, overflow, must-show clip). Not pixel snapshots.
argument-hint: optional path or viewport id
---

# /layout-content-view

Load skill **layout-content-view**. Expand `references/predicates.md` only to classify a finding. Expand `references/pilot-devprofile.md` when cwd is the profile site.

`$ARGUMENTS` = path and/or viewport id (`phone` `tablet` `desktop`). Empty = all feature-map paths × default viewports.

## Immediate actions

1. Load the verify feature map if present; else list routes. No second `SURFACES[]`.
2. Measure document + inner boxes; `classify` / `report` via `scripts/lcv.mjs`.
3. Stress one must-show node (long string). Inner overflow + stable view box → fail.
4. Apply **one** recipe for the first fail. Re-measure that view.
5. PNG baselines stay on the verify skill.

## Emit

```markdown
## LCV
| Field | Value |
|-------|--------|
| **paths** | |
| **viewports** | |
| **findings** | kind × id (fail/info) |
| **shot** | one recipe applied, or none |
| **compose** | verify-* skill or none |
```
