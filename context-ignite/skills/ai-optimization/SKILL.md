---
name: ai-optimization
version: 0.1.0
description: >
  Prune and compress code context with relevance scores and token budgets.
  Use for large-repo edits, debug, and Context Sage.
metadata:
  author: p10ns11y <9104920+p10ns11y@users.noreply.github.com>
  tags:
    - context
    - tokens
    - compression
    - fission
---

# ai-optimization (Context Sage)

Port copy. Canonical file remains in https://github.com/p10ns11y/skills on master.

> **Load rule:** Formal SoT below. Lang playbooks → [references/](references/) only if needed. Expand [references/english-procedure.md](references/english-procedure.md) **only if** scoring/budget still ambiguous.
> **CLT:** this skill is the primary **agent-extraneous** reducer under [../rules/clt-dual-load.mdc](../rules/clt-dual-load.mdc) — prune before deep/coding fill; do not strip germane VERIFY evidence.

## Purpose

Cut input-code tokens without trading correctness. Pair with [fusion-sage](../fusion-sage/SKILL.md) for synthesis/surplus. Skip for a one-file typo or when the full file is already pasted.

## Prerequisites

- Repo on disk; verify cmds from target `AGENTS.md`.
- Optional packer: `python` 3 for [scripts/context-sage.py](scripts/context-sage.py).
- Hosts that support `run_script` should invoke that script rather than paraphrasing a pack.

## Instructions

```text
Fission  ≔ prune + compress + budget   // this skill
Fusion   ≔ synthesis + surplus         // [fusion-sage](../fusion-sage/SKILL.md)
Score    ∈ 0..100                      // relevance
Budget   ≔ context cap for *input* code/docs (not model CoT)

A1  Relevance ≻ Completeness     // ~80% value from ~5–15% of code
A2  Hierarchy first              // structure before bodies
A3  Language-native compression  // AST/API idioms per lang
A4  Budget dictates form         // lower score → denser form
A5  Progressive disclosure       // expand only on request / auto-expand rules
A6  Correctness ⊥ tokens         // never trade correctness for compression
A7  Evaluate(δ) ≔ (C, E, η)      // keep tactics with Δ>0
```

Pair: [fusion-sage](../fusion-sage/SKILL.md) · [master-planner](../master-planner/SKILL.md) overlays · [examples/overlays/](../examples/overlays/).

```text
intent → map (modules/API surface) → score → compress form → budget trim → act
```

| Step | Do |
|------|-----|
| **1 Intent** | goal ∈ {implement, debug, refactor, explain, test, migrate, optimize}; symbols; scope; constraints |
| **2 Map** | lightweight module + public surface + recent files + arch style |
| **3 Score** | table below (0–100) |
| **4 Form** | score → compression tier |
| **5 Budget** | hard cap **35%** context for input code; reserve **~25%** for reasoning+answer; drop lowest score first |

### Relevance score

| Signal | Δ |
|--------|---|
| symbol exact match | +40 |
| keyword in path/name | +20 |
| centrality (many importers) | +15 |
| business-critical (`auth`, `payment`, `core`, model def) | +15 |
| recency (last ≤3 turns) | +10 |
| `test/` `__pycache__/` `node_modules/` `dist/` `target/` | −50 (*waive* if goal is debug/test — boost instead) |

### Compression tiers

| Score | Form |
|-------|------|
| >85 | full file stripped (noise out) |
| 60–85 | signature + critical blocks + docstring |
| 30–60 | public API + 1-line purpose + key edges |
| <30 | name only + "see prior context" |

### Cross-lang strip rules

- Drop: licenses, generated markers, excess blank lines, repetitive getters
- Collapse standard validation/error-map to one sentence
- Use `...` when name+signature+context makes body obvious
- ≤2 full function bodies per file unless score >90

Lang detail: [references/typescript-optimizer.md](references/typescript-optimizer.md) · [references/python-optimizer.md](references/python-optimizer.md) · [references/rust-optimizer.md](references/rust-optimizer.md).

### Accuracy guardrails (never violate)

| Rule | Detail |
|------|--------|
| **Never compress** | auth, security, payments, secrets, permissions, migrations/schema, lockfile/deps edits, CI/E2E/build config, **files you will edit**, callers of changed symbols (sig+imports min) |
| **Debug / flaky** | full suspect files + config + related tests |
| **Before edit** | if body was summarized → read full file first |
| **No invention** | never invent APIs/patterns not seen |
| **Done** | state assumptions; run verify (`type-check`, `lint`, tests) |

Auto-expand (do not wait): edge cases in summarized body; user `expand <symbol>` / `show full <file>`; you would write "assuming standard pattern" without having read it.

Output:

```text
🧠 Context Sage | Budget: Xk / Yk (Z%) | Relevance: R/100 | Files: N (forms…)

## Snapshot   (2–4 lines: stack, key dirs, verify cmds)
## Context    (structured, tiered)
## Action     (minimal diff/answer + assumptions)
## Token note (expand <name> to deepen)
```

Hand off to fusion-sage for architecture / long-term design.

## Available Scripts

| Script | Purpose | Arguments |
|--------|---------|-----------|
| [scripts/context-sage.py](scripts/context-sage.py) | Build a token-budgeted context pack (analyze → pack) for large-repo edits without dumping the tree | `analyze --project DIR --query Q --budget N --lang LANG`; then `pack --output context-pack.md` |

Hosts with `run_script` **must** call the script — do not paraphrase a pack in prose.

```text
run_script("scripts/context-sage.py", ["analyze", "--project", DIR, "--query", Q, "--budget", "45000", "--lang", LANG])
run_script("scripts/context-sage.py", ["pack", "--output", "context-pack.md"])
```

Shell equivalent (Grok Build / local cursor-agent on laptop-1):

```bash
python scripts/context-sage.py analyze --project "$REPO" --query "$GOAL" --budget 45000 --lang rust
python scripts/context-sage.py pack --output context-pack.md
```

Collab-finder / Tauri large surface: set `--project` to the app root, `--query` to the hunt or IPC slice (e.g. `finder-reactor promote pack`), `--lang` to `typescript` or `rust` as needed. Keep auth, DB paths, and files you will edit at full body after the pack.

Proof notes: [references/tested.md](references/tested.md).

## Examples

User: "Huge repo. Add password reset. Don't dump the tree."

Agent: score by symbol/path; keep auth + files you will edit at full body; compress `<30` names only. Pack with:

```text
run_script("scripts/context-sage.py", ["analyze", "--project", ".", "--query", "password reset", "--budget", "45000", "--lang", "typescript"])
run_script("scripts/context-sage.py", ["pack", "--output", "context-pack.md"])
```

Then run project verify cmds.

User: "Context window is full, explain the queue module."

Agent: map public API, emit 30–60 tier summaries, offer `expand <symbol>`.

User: "Grok Build is thrashing on collab-finder — pack the reactor before editing."

Agent: from the skill dir (or skill-relative path):

```text
run_script("scripts/context-sage.py", ["analyze", "--project", "/path/to/collab-finder", "--query", "finder-reactor promote", "--budget", "45000", "--lang", "typescript"])
run_script("scripts/context-sage.py", ["pack", "--output", "context-pack.md"])
```

Never compress SQLite paths, application packs, or files you will edit.

## Limitations

- Does not replace fusion-sage for architecture.
- Compression never applies to auth/secrets/edit targets.
- `context-sage.py` is a helper, not a substitute for reading files you will change.
- Overlay paths under `.agents/skills/ai-optimization/references/` are optional.

## Troubleshooting

| Error / symptom | Cause | Fix |
|-----------------|-------|-----|
| Invented API in the patch | Compressed a file you needed to edit | Read full file; never compress edit targets |
| Verify skipped "to save tokens" | Budget ate the verify step | Reserve ~25% for answer+verify; run cmds |
| Pack misses the bug | Debug path used summaries | Full suspects + config + tests |
| `context-sage.py` missing | Script not run from skill dir | `run_script` with skill-relative path |

**Done when:** intent+scores applied; budget respected; guardrails held; verify cmds run for multi-file edits; fusion handoff noted when architecture.

**Anti-patterns:** dump whole repo "just in case" · compress auth/edit targets · invent unseen APIs · skip verify because "context was tight" · dual-load full English playbooks every turn.

English expansion: [references/english-procedure.md](references/english-procedure.md).
