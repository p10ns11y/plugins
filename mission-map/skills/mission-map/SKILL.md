---
name: mission-map
version: 0.1.0
description: >
  Build a critical-path ops map with PERT bands and shock signposts.
  Use for /mission-map or replanning after a distraction.
metadata:
  author: p10ns11y <9104920+p10ns11y@users.noreply.github.com>
  tags:
    - planning
    - pert
    - critical-path
    - ops
---

# mission-map

> **Load rule:** This file owns the **map**. Control-plane phases stay in `control-graph`. Emptiness (unknown map) stays in `eva-emptiness`. Do not forecast life at 7 nines.

## Purpose

Produce a brief you can execute and **replan**: what / how / when under uncertainty. Not a prophecy.

Use when you need calculated risk, a critical path, or a replan after a reject, deadline, illness, or shiny detour. Skip if the next act is already one file and a known verify command.

## Prerequisites

- Plugin installed (`mission-map`). Commands below run from that install directory.
- Optional numbers: `make` (C kernels), `cargo` (Rust graph CLI).
- Optional host timer: `mm-lifeos-graph` writes a local Mission card. Do not invent a vault path.

## Instructions

**Mission impossible** here means a brief you can execute and replan.

| Class | Meaning | Action |
|-------|---------|--------|
| **Do** | On the critical path; you can start it | Schedule; assign hours |
| **Risk** | Calculated: blast × how soon it can fire | Mitigate or watch; do not freeze |
| **Wait** | Blocked on someone else or a date | Signpost only; do not invent work |
| **Park** | Slack / distraction (∇T ≈ 0) | Refuse this tick |

Never print a single calendar date as destiny. Print **bands** \(a / m / b\) and the **next Do**.

1. **Name \(G\)** — one checkable arrival. If \(G\) is empty or uncheckable, stop and Ask.
2. **Name \(x\)** — current facts only (no PII dumps).
3. **DAG** — stages with edges. Mark the **critical path**. Reject a map with no stages.
4. **For each stage** fill: What · How · When (\(a,m,b\) or a hard deadline) · Owner · class.
5. **Effort** — hours only on Do nodes with high \(\partial T/\partial u\).
6. **Signposts** — `watch` → `fires_when` → `continue | switch | Ask`. Every Risk needs one.
7. **On shock** — re-run steps 3–6 on the remaining DAG only.
8. **LLM room** — propose a missing stage or band; human confirms.

Optional numbers (from the plugin root):

```bash
make -C c test
mm-kern pert 2 4 8
mm-kern hazard 0.1 4 3
mm-kern bayes 2 4 8 3
```

DAG MC (`dag_mc_p50`/`p90`), regime beliefs (`regime_*`), and Risk ranks (`risk id=`) print from the Rust CLI. See [references/kernels.md](references/kernels.md). JSON shape: [references/map-schema.md](references/map-schema.md).

## Examples

User: `/mission-map` after a hiring-loop shock.

Agent: name \(G\) (one checkable arrival), list stages with class Do, Risk, Wait, or Park, print \(a, m, b\) on Do nodes, one **next Do**, and a signpost per Risk. Do not print a single destiny date.

Kernel smoke:

```bash
mm-kern pert 2 4 8
```

Sample DAG: [sample-map.json](../../examples/sample-map.json).

## Done when

- One \(G\), one critical path, one **next Do**
- Every Risk has a signpost
- Parks are named so they can be refused
- No 7-nines forecast

## Limitations

- Not a future oracle. Bands move when facts move.
- Does not replace control-graph phases or eva-emptiness when the map itself is missing.
- C and Rust kernels are optional; a valid map can be prose plus the class table.
- Email and other PII stay off the public map. See [map-schema](references/map-schema.md).

## Troubleshooting

| Error / symptom | Cause | Fix |
|-----------------|-------|-----|
| No next Do | Every remaining node is Wait or Park | Name a Do on the residual critical path, or Ask |
| `mm-kern` missing | Plugin bin not built | From plugin root: `make -C c` then rerun |
| Cargo graph CLI fails | Invalid JSON vs [map-schema](references/map-schema.md) | Check g, id, a, m, b, depends_on, class |
| Silent formula overwrite | LLM replaced numbers without a confirm | Restore bands; human confirms step 8 |
| Tourist trip as \(G\) | Arrival is not checkable | Reject; pick a verifyable \(G\) |

## Related

- Schema: [references/map-schema.md](references/map-schema.md)
- Kernels: [references/kernels.md](references/kernels.md)
- Example: [sample-map.json](../../examples/sample-map.json)
- control-graph · eva-emptiness · north-star-compass
