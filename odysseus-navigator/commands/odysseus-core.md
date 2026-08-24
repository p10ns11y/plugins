---
description: Nail the deep core in one pass — Ithaca, one bottleneck, at most one Odysseus mistake, one next. Faster than /eva. Not a rewrite of control-graph.
argument-hint: optional goal / plan / dump
---

# /odysseus-core — faster intelli nail

Load skill **odysseus-navigator** (bundled in this plugin’s `skills/`). If the skill is missing, follow this file — it is the **fast path**. Do **not** start EVA’s Prior→Probe ritual. Do **not** open a Control Card unless a hook below says so.

## Immediate actions

1. **Ithaca** — one sentence: the real user/business outcome. Not the architecture.
2. **Core** — the single bottleneck that, if moved, most advances Ithaca. (HODA “critical zone” — do not paste HODA.)
3. **At most one Mistake** from {Cyclops, Sirens, Helios, Circe, Winds, Scylla, Prophecy} — or `none`. Rank by harm to Ithaca; drop the rest.
4. **Waters** — calm | novel-pressure | crisis | R&D | stakeholder. Spirit = Ithaca only unless the skill’s circumstance table matches. Calm → no cleverness.
5. **next** — one concrete action (path, cmd, Ask, or skip).
6. **Route (first match):**
   - ≥2 of {unknowns dominate, futures disagree, auth/irreversible unclear, user asked blank-sheet} → `eva_hook=Ask` and **suggest** `/eva` (do not silent-launch)
   - multi-step / thrash / “until done” → `cg_hook=ORIENT` and **suggest** control-graph Card
   - heading / PERT / critical-path math → **suggest** `/mission-map`
   - else implement `next` only if it is a ≤2-file fix and `mistakes=none`
7. **Stop.** No subagents. No catalog dump. No myth essay.

## Emit (required)

```markdown
## Odysseus
| Field | Value |
|-------|--------|
| **ithaca** | |
| **core** | (one bottleneck) |
| **waters** | calm \| novel-pressure \| crisis \| R&D \| stakeholder |
| **mistakes** | none \| (exactly one name) |
| **antidotes** | |
| **spirit** | Ithaca [\| Metis \| Endurance \| Curiosity \| Leadership] |
| **why_spirit** | |
| **cg_hook** | skip \| ORIENT \| PLAN \| HITL_* \| EXECUTE+budget \| VERIFY \| REVIEW_GATE \| dual-run |
| **eva_hook** | skip \| continue \| switch \| Ask |
| **next** | |
```

Goal / plan / dump from the user (may be empty):

```text
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask for Ithaca in one short question, then continue.
