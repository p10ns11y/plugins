# /eva-workflow — Cursor stand-in for Grok `/workflow eva-emptiness`

Grok’s Rhai host (`.grok/workflows/*.rhai` + `/workflows` dashboard) does **not** run inside Cursor. This command runs the **same skeleton** as a structured Agent session.

## Goal

$ARGUMENTS

If `$ARGUMENTS` / my follow-up goal is empty, ask once for a one-sentence blank-sheet outcome, then continue.

## Phased run (host yourself — report after each phase)

Follow skill **eva-emptiness**. After each phase, short Card update only (no transcript dump).

| Phase | done_when |
|-------|-----------|
| **Prior** | Card: emptiness_score, knowns/unknowns, idk, probe_budget |
| **Probe** | One DOE Q answered (or HOOTL default recorded) + explore evidence_gain |
| **Simulate** | ≥2 prior-diverse forks (prefer 3 Task subagents: conservative / generative / causal) + bias_map |
| **Score** | Fresh review Role: evidence_gain, robustness, trauma_flags, critical_path → next=Act\|Ask |
| **ActOrAsk** | If Ask: structured HITL preview only. If Act: critical-path edits + verify cmds |

## Rules

- Skip EVA if emptiness_score=low and path is clear.
- Never always-approve / yolo; auth unknown → Ask.
- Fan-out independent Simulate forks; serialize human asks.
- End by **suggesting** (not launching): next workflow/skill names for delivery or research.

## Done when

Card complete + Act verified **or** Ask preview ready.
