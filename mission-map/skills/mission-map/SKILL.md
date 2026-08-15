---
name: mission-map
description: >
  Build a Mission-Impossible-style ops map: steps, calculated risks, what/how/when,
  and how to adjust when outside shocks hit. Not a future oracle. Uses critical
  path, PERT bands, and sensitivity (∇T) to rank effort. Use when the user runs
  /mission-map, says mission map, calculated risk, what to do when, or how to
  replan after a distraction.
---

# mission-map

> **Load rule:** This file owns the **map**. Control-plane phases stay in `control-graph`. Emptiness (unknown map) stays in `eva-emptiness`. Do not forecast life at 7 nines.

## When to use

- Need a clear **what / how / when** list under uncertainty
- Outside world will throw rejects, deadlines, illness, shiny detours
- Want calculated risk, not “what will happen”
- Skip if the next act is already one file and a known verify command

## Contract

**Mission impossible** here means: a brief you can execute and **replan**, not a prophecy.

| Class | Meaning | Action |
|-------|---------|--------|
| **Do** | On the critical path; you can start it | Schedule; assign hours |
| **Risk** | Calculated: blast × how soon it can fire | Mitigate or watch; do not freeze |
| **Wait** | Blocked on someone else or a date | Signpost only; do not invent work |
| **Park** | Slack / distraction (∇T ≈ 0) | Refuse this tick |

Never print a single calendar date as destiny. Print **bands** \(a / m / b\) and the **next Do**.

## Steps

1. **Name \(G\)** — one checkable arrival.
2. **Name \(x\)** — current facts only (no PII dumps).
3. **DAG** — stages with edges. Mark the **critical path**.
4. **For each stage** fill: What · How · When (\(a,m,b\) or a hard deadline) · Owner · class.
5. **Effort** — hours only on Do nodes with high \(\partial T/\partial u\).
6. **Signposts** — `watch` → `fires_when` → `continue | switch | Ask`.
7. **On shock** — re-run steps 3–6 on the remaining DAG only.
8. **LLM room** — propose a missing stage or band; human confirms.

Optional numbers:

```bash
make -C {plugin}/c test
{plugin}/bin/mm-kern pert 2 4 8
cd {plugin}/rust && cargo run -- ../examples/sample-map.json
```

`{plugin}` is the install path of this plugin (marketplace or `~/Work/personal/plugins/mission-map`).

## Done when

- One \(G\), one critical path, one **next Do**
- Every Risk has a signpost
- Parks are named so they can be refused
- No 7-nines forecast

## Do not

- Treat a tourist trip, a new side app, or a resend of a dead process as arrival
- Spend the tick on Park nodes
- Silent formula/RSI overwrite

## Related

- Schema: [references/map-schema.md](references/map-schema.md)
- Kernels: [references/kernels.md](references/kernels.md)
- Example: `{plugin}/examples/sample-map.json`
- `control-graph` · `eva-emptiness` · `north-star-compass`
