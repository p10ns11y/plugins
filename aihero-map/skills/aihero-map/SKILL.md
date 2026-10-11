---
name: aihero-map
description: >-
  Alignment map from Matt Pocock's AI Hero skills onto house skills.
  Load the house row. Fetch https://www.aihero.dev/skills.md once.
  The Claude plugin is Claude Code only. Do not copy the body. Use for /aihero-map,
  an alignment name, or which stack wins on an overlap.
  Not an ingestion. Not a pstack fork. Not control-graph Outer.
---

# aihero-map

> **Load rule:** This file is the **map SoT**. Expand [references/map.md](references/map.md) only to pick a row. Do **not** paste AI Hero skill bodies.

```text
AM       : aihero-map (this skill)      // map plane
Index    : https://www.aihero.dev/skills.md  // one agent fetch; the HTML page is not
Page     : <skill>.md                    // one row, markdown
Source   : https://github.com/mattpocock/skills  // npx source; not a required install
Setup    : https://www.aihero.dev/skills-setup-matt-pocock-skills.md  // product repo, once
PM       : pstack-map                    // playbooks, Lauren Tan
IR       : intelli-route                 // at most four loads
```

A1  Map; do not copy. Fetch `skills.md`. Do not vendor the bodies into this repo.
A2  On an overlap, load the stronger-claim house skill in the map.
A3  Credit Matt Pocock on every emit. `claude plugins install` is Claude Code only.
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
3. Fetch https://www.aihero.dev/skills.md once when the name is not in the table. For a matched row, fetch that row's `.md` page. Do not fetch https://www.aihero.dev/skills.
4. One install per harness, from README.md "Right way, by harness". Claude: `claude plugin install mattpocock-skills@claude-plugins-official`. Cursor: `npx skills@latest add mattpocock/skills -a cursor`. Grok: `npx skills@latest add mattpocock/skills -a grok`. Do not combine a plugin with `npx skills add`. This repo does not install the bodies.
5. Setup is once per product repo, before those upstream skills: https://www.aihero.dev/skills-setup-matt-pocock-skills.md. It writes `docs/agents/`. Keep `AGENTS.md` as the file this harness reads.
6. On an overlap, the stronger-claim column wins. Do not install the upstream skill for that name.
7. Emit the table. Keep the credit line.

## Emit (required)

```markdown
## Aihero-map
| Field | Value |
|-------|--------|
| **alignment** | |
| **house** | |
| **content** | https://www.aihero.dev/skills.md |
| **source** | https://github.com/mattpocock/skills |
| **stronger** | |
| **credit** | Matt Pocock |
| **next** | |
```
