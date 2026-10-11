---
name: aihero-map
description: >-
  Alignment map from Matt Pocock's AI Hero skills onto house skills.
  Load the house row. Load the catalog once for the body.
  The AI harness needs the skills repo. Do not copy the body. Use for /aihero-map,
  an alignment name, or which stack wins on an overlap.
  Not an ingestion. Not a pstack fork. Not control-graph Outer.
---

# aihero-map

> **Load rule:** This file is the **map SoT**. Expand [references/map.md](references/map.md) only to pick a row. Do **not** paste AI Hero skill bodies.

```text
AM       : aihero-map (this skill)      // map plane
Body     : https://www.aihero.dev/skills  // content, load once
Harness  : https://github.com/mattpocock/skills  // AI harness, required
PM       : pstack-map                    // playbooks, Lauren Tan
IR       : intelli-route                 // at most four loads
```

A1  Map; do not copy. Load the body once from the catalog. Do not vendor it.
A2  On an overlap, load the stronger-claim house skill in the map.
A3  Credit Matt Pocock on every emit. The AI harness is the skills repo.
A4  pstack, by Lauren Tan, stays the execution playbook. This map does not replace it.

**Mission:** Name the house skill for an alignment name without a second copy of AI Hero.

## Activate / Skip

| Signal | Action |
|--------|--------|
| `/aihero-map` · an alignment name · which stack wins | load AM; emit **Map** |
| The house skill for that row is already the only load | skip the essay; name the row |
| triage, wizard, teach, wait-what, throwaway prototype | leave upstream |

## Do

1. Match one alignment name, or `skip`.
2. Load the house skill in that row.
3. Load the body once from https://www.aihero.dev/skills. Do not copy it here.
4. The AI harness needs https://github.com/mattpocock/skills.
5. On an overlap, the stronger-claim column wins.
6. Emit the table. Keep the credit line.

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
