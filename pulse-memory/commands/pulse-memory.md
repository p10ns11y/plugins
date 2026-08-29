---
description: Pulse instead of dump — tag claims, resolve contradictions, inject sparse memory snippets.
argument-hint: optional dump / files / next action
---

# /pulse-memory

Load skill **pulse-memory** (bundled in this plugin’s `skills/`). Former name: `archive-not-memory`.

`$ARGUMENTS` = notes, file paths, or the next action to admit against.

## Immediate actions

1. Extract claims. Stamp **hint tags** on every one: `source`, `time`, `status`, `kind`, `lock`.
2. Admissions: keep only traces that would change the **next action**.
3. Conflicts: list, do not average. Prefer later `time`, then `tool-verified` > `user-stated` > `inferred` > `unknown`. Else **not in the evidence**.
4. Emit pulses (≤ ~120 tokens each), not a transcript dump.
5. File cycle: `/workflow pulse-memory`. **Always** `as_of` (ISO-8601). `mode`: `both` (default) \| `thinking` \| `harness`. Paths: thinking = dump/session; harness = Dashboard/`next_action`. Copy-paste: skill `references/usecases.md`.

Do not invent completeness. Do not save inferred fills as `locked`.
