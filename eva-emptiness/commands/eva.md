---
description: Start EVA emptiness session — Prior→Probe→Simulate→Score→ActOrAsk under plan mode
argument-hint: optional goal / blank-sheet problem
---

# /eva — epistemic emptiness harness

Load skill **eva-emptiness** (this plugin). Follow its Inner DAG; Outer phases stay in **control-graph** if multi-step.

## Immediate actions

1. Enter **plan mode** (`/plan`) before any file edits.
2. Stay on permission **ask** — never `--always-approve` / `--yolo`. Plugin PreToolUse tether (C `bin/eva-tether` or shell fallback) enforces trauma denies; optional secure compile: `/eva-tether-init --yes`.
3. On the Control Card (or plan), write:
   - `emptiness_score`, `knowns[]`, `unknowns[]`, at least one `idk`
   - `probe_budget` (default 3)
   - `disprove_with` (cheapest check that would prove the #1 assumption wrong)
4. Ask **one** DOE clarifying question that most reduces ignorance (use Grok Q&A if available).
5. After answers: spawn parallel **explore** probes, then Simulate with prior agents:
   - `eva-emptiness:prior-conservative`
   - `eva-emptiness:prior-generative`
   - `eva-emptiness:prior-causal`
   Prefer worktree isolation for forks that edit. Each fork should return `disprove_with`.
6. Blind **Score** in a fresh context (plan + diffs + verify logs only). Build `bias_map` from fork disagreement.
7. **ActOrAsk** — continue \| switch \| Ask; Act only with Claim-via-critical-path; Ask on auth horizon / contradiction.
8. **Suggest** (do not silent-launch) a next workflow when useful:
   - background EVA instead: `/workflow eva-emptiness {"goal":"…"}` (requires `.rhai` installed under `~/.grok/workflows/` or project `.grok/workflows/`)
   - multi-worker delivery: `/workflow multi-agent-delivery`
   - cold repo map: `/workflow context-ignite`
   - external claims: `/deep-research …`

`/eva` = interactive HITL. `/workflow eva-emptiness` = host-scheduled background. Plugin install ≠ workflow install.  
`/eva-tether-init` = status/compile of the secure C tether (consent with `--yes`).

Goal context from user (may be empty):

```text
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask for the blank-sheet goal in one short question, then continue.
