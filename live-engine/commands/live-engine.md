---
description: Run the Live engine action runner on the current turn. One live working set, verify before irreversible acts.
argument-hint: optional working-set name or mode hint
---

# /live-engine

Load skill **live-engine**.

`$ARGUMENTS` = optional name for the live working set or a mode hint (`rest`, `focus`, `sprint`, `recover`). If empty, infer from the current turn.

## Immediate actions

1. Pick one mode and name the live working set.
2. Load only skills the working set needs; stay inside the host load cap.
3. Verify claims before acting; pause on irreversible acts (send, spend, merge, delete, public post).
4. Speak as one first person; do not expose routing machinery unless asked.
5. After a sprint, recover: distill, compact, drop stale context.
