---
description: Run the CoS process workflow on the current turn. One live context, verify before irreversible acts.
argument-hint: optional live context or mode hint
---

# /cos

Load skill **cos**.

`$ARGUMENTS` = optional name for the live context or a mode hint (`rest`, `focus`, `sprint`, `recover`). If empty, infer from the current turn.

## Immediate actions

1. Pick one mode and name the live context.
2. Load only skills the live context needs; stay inside the host load cap.
3. Verify claims before acting; pause on irreversible acts (send, spend, merge, delete, public post).
4. Speak as one first person; do not expose routing machinery unless asked.
5. After a sprint, recover: distill, compact, drop stale context.
