---
description: Map onto Cursor pstack (Lauren Tan, MIT). Load installed pstack or house fallback. House HITL on irreversible work.
argument-hint: optional task / playbook / dump
---

# /pstack-map

Load skill **pstack-map**. Expand `references/map.md` only to pick a playbook.

`$ARGUMENTS` = task. If empty, match from the current turn.

This is **not** a pstack fork. Credit Lauren Tan. Do not copy playbook bodies.

## Immediate actions

1. Match **one** playbook (or `skip` if ≤2-file obvious).
2. If pstack is installed, load that skill / `/poteto-mode`. Else use the house column.
3. `hitl=required` for secrets, prod, irreversible git, CV, or unknown auth. Else proceed on reversible work.
4. Emit `cg_hook` / `eva_hook` only. Do not inline control-graph or EVA.
5. Graphite land, benny, overnight yolo: skip. Verify; wait for the human to push.

## Emit (required)

```markdown
## Pstack-map
| Field | Value |
|-------|--------|
| **playbook** | |
| **pstack** | installed: … \| missing |
| **house** | |
| **cg_hook** | skip \| ORIENT \| PLAN \| HITL_* \| EXECUTE+budget \| VERIFY \| REVIEW_GATE |
| **eva_hook** | skip \| continue \| switch \| Ask |
| **hitl** | none \| required (reason) |
| **credit** | Lauren Tan / pstack MIT · https://github.com/cursor/plugins/tree/main/pstack |
| **next** | |
```
