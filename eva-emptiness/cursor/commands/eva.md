# /eva — epistemic emptiness (interactive)

Load and follow the **eva-emptiness** skill. Pair with **control-graph** for Outer phases if multi-step.

## Do now

1. Treat this as a blank-sheet / high-unknown task until proven otherwise.
2. Write on a Control Card: `emptiness_score`, `knowns[]`, `unknowns[]`, ≥1 honest `idk`, `probe_budget=3`, `disprove_with`.
3. Ask **one** DOE clarifying question that most reduces ignorance (wait for my answer if I’m here).
4. Probe with readonly explore (grep/read); append `evidence_gain` only for new confirm/disprove.
5. Simulate with three prior lenses (can use Task/subagents in parallel):
   - **conservative** — refuse/delete when evidence thin
   - **generative** — structure from analogy when data≈none
   - **causal** — name `disprove_with` (cheapest check that would prove the top assumption wrong)
6. Blind Score: plan + evidence only; build `bias_map` from disagreements.
7. **ActOrAsk** — continue \| switch \| Ask; Act only with Claim-via-critical-path. No yolo.
8. Suggest next (name only): multi-agent delivery / context-ignite / stay on HITL.

If I pasted a goal after `/eva`, use it. Otherwise ask for one sentence.

**Auth tether:** `~/.cursor/hooks/eva-tether-shell.sh` on `beforeShellExecution` (prefers plugin `bin/eva-tether` C binary; portable shell fallback). Symlink from the plugin so the hook can find `bin/`. Ordinary `git push` → ask; force-push / yolo / reset-hard → deny.

**Cursor vs Grok:** This is the interactive path. For a phased stand-in of Grok’s Rhai workflow, use `/eva-workflow`.
