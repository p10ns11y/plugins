---
description: Build a Mission-Impossible-style ops map (steps, calculated risk, replan). Not a forecast.
argument-hint: optional goal / current shock
---

# /mission-map

Load skill **mission-map**. Fill What / How / When / Risk / Wait / Park. Print one **next Do**.

## Immediate actions

1. Name checkable **G**. Do not print a single destiny date.
2. List stages as a DAG. Mark **Do / Risk / Wait / Park**.
3. PERT bands \(a/m/b\). Optional: `bin/mm-kern` or `mission-map-graph examples/sample-map.json --mermaid`.
4. Print heading: `heading=` `cos=` `residual=` plus mermaid arrows along \(\hat{u}_G\). Parks are orthogonal.
5. Put hours only on the critical path. Park slack.
6. Write signposts: `continue | switch | Ask` for outside shocks.
7. LLM may **propose** a missing stage or band. Human confirms. No silent formula rewrite.
8. Compare snapshots with `--compare then.json` (delta remaining \(t_e\), not a destiny date).
