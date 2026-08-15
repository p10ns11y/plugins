---
description: Build a Mission-Impossible-style ops map (steps, calculated risk, replan). Not a forecast.
argument-hint: optional goal / current shock
---

# /mission-map

Load skill **mission-map**. Fill What / How / When / Risk / Wait / Park. Print one **next Do**.

## Immediate actions

1. Name checkable **G**. Do not print a single destiny date.
2. List stages as a DAG. Mark **Do / Risk / Wait / Park**.
3. PERT bands \(a/m/b\). Optional: `bin/mm-kern` or `mission-map-graph examples/sample-map.json`.
4. Put hours only on the critical path. Park slack.
5. Write signposts: `continue | switch | Ask` for outside shocks.
6. LLM may **propose** a missing stage or band. Human confirms. No silent formula rewrite.
