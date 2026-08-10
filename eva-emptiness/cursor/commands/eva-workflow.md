# /eva-workflow — Cursor stand-in for Grok `/workflow eva-emptiness`

Grok’s Rhai host (`.grok/workflows/*.rhai` + `/workflows` dashboard) does **not** run inside Cursor. This command runs the **same skeleton** as a structured Agent session.

## Goal

$ARGUMENTS

If `$ARGUMENTS` / my follow-up goal is empty, ask once for a one-sentence blank-sheet outcome, then continue.

## Phased run (host yourself — report after each phase)

Follow skill **eva-emptiness**. After each phase, short Card update only (no transcript dump).

| Phase | done_when |
|-------|-----------|
| **Prior** | Card: emptiness_score, knowns/unknowns, idk, probe_budget, `disprove_with` |
| **Probe** | One DOE Q answered (or HOOTL default recorded) + explore evidence_gain |
| **Simulate** | ≥2 prior-diverse pathways (prefer 3 Task subagents: conservative / generative / causal) + bias_map; each fork names `disprove_with` |
| **Score** | Fresh review Role: evidence_gain, robustness, option-preserve, trauma_flags, critical_path → next=continue\|switch\|Ask |
| **ActOrAsk** | If Ask: structured HITL preview only. If switch: re-ORIENT with new pathway. If continue: critical-path edits + verify cmds |

## Rules

- Skip EVA if emptiness_score=low and path is clear.
- Never always-approve / yolo; auth unknown → Ask.
- Keep Cursor `beforeShellExecution` tether wired (`eva-tether-shell.sh` → prefers C `bin/eva-tether`, shell fallback).
- Fan-out independent Simulate forks; serialize human asks.
- End by **suggesting** (not launching): next workflow/skill names for delivery or research.

## Done when

Card complete + Act verified **or** Ask preview ready.
