---
description: Full Odysseus Navigator — diagnose all matching mistakes, prescribe antidotes, gate spirits, hook control-graph / EVA.
argument-hint: optional goal / plan / dump
---

# /odysseus — Navigator (full table)

Load skill **odysseus-navigator**. Expand its English reference **only if** a mistake or spirit is still ambiguous.

Prefer **`/odysseus-core`** when you want one bottleneck. Use this command when several smells are in play.

## Immediate actions

1. Name Ithaca (one sentence).
2. Diagnose **all** matching Mistakes (Cyclops, Sirens, Helios, Circe, Winds, Scylla, Prophecy) — or `none`. Quote each myth in ≤1 line.
3. Waters + spirit (Ithaca always; others iff circumstance table).
4. Prescribe antidotes as **hooks** — `cg_hook`, `eva_hook`. Do not inline control-graph Outer or EVA Inner.
5. Rank by harm to Ithaca; put the top antidote in `next`.
6. If `mistakes=none`: affirm + sharpen one next step. Do not lecture.
7. Suggest (do not silent-launch): `/eva` · control-graph · `/mission-map` · `/odysseus-core` (if this reply got long).

## Emit (required)

```markdown
## Odysseus
| Field | Value |
|-------|--------|
| **ithaca** | |
| **waters** | calm \| novel-pressure \| crisis \| R&D \| stakeholder |
| **mistakes** | none \| Cyclops, Sirens, … |
| **antidotes** | Opacity \| BoringEvo \| SacredProd \| YAGNI \| Resilience \| Incremental \| Observability |
| **spirit** | Ithaca [\| Metis \| Endurance \| Curiosity \| Leadership] |
| **why_spirit** | |
| **cg_hook** | skip \| ORIENT \| PLAN \| HITL_* \| EXECUTE+budget \| VERIFY \| REVIEW_GATE \| dual-run |
| **eva_hook** | skip \| continue \| switch \| Ask |
| **next** | |
```

Stay on permission **ask**. Never `--always-approve` / `--yolo` (Helios + Cyclops). Auth unknown → `eva_hook=Ask`.

Goal / plan / dump from the user (may be empty):

```text
$ARGUMENTS
```
