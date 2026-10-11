---
description: Map an AI Hero alignment name onto a house skill. Matt Pocock. Do not copy the upstream body.
argument-hint: optional alignment name
---

# /aihero-map

Load skill **aihero-map**. Expand `references/map.md` only to pick a row.

`$ARGUMENTS` = alignment name. If empty, match from the current turn.

This is **not** an ingestion. Credit Matt Pocock. Do not copy skill bodies.

## Immediate actions

1. Match **one** alignment name (or `skip`).
2. Load the house skill in that row.
3. Load the body once from https://www.aihero.dev/skills.
4. The AI harness needs https://github.com/mattpocock/skills.
5. On an overlap, the stronger-claim column wins.
6. Emit the **Aihero-map** table with the credit row.

## Emit (required)

```markdown
## Aihero-map
| Field | Value |
|-------|--------|
| **alignment** | |
| **house** | |
| **content** | https://www.aihero.dev/skills |
| **harness** | https://github.com/mattpocock/skills |
| **stronger** | |
| **credit** | Matt Pocock |
| **next** | |
```
