---
name: craft
version: 0.1.0
description: >
  Robert C. Martin clean-code chain for agents (work in progress): acceptance
  tests from spec before any coder runs, then coder, cleaner with CRAP thresholds
  on touched functions, hardener with mutation score, then QA. Use for /craft,
  crap score, mutation testing, boy-scout cleanup in touched files, or clean seams.
  Not a router. Not a merge bot.
---

# craft

> **Load rule:** This file owns the chain. Tables live in [references/chain.md](references/chain.md). Thresholds live in [references/thresholds.md](references/thresholds.md). Open those only to pick a step or a number. Do not paste book text.

```text
// Signature
CR   : craft (this skill)
ACC  : acceptance from human spec — Gherkin + QA procedure
COD  : coder — unit tests + implementation
CLN  : cleaner — names, small functions, boy-scout in touched files only
HRD  : hardener — mutation testing on touched functions
QA   : QA agent — executable acceptance procedure

// Axioms
A1  Acceptance tests come from the spec before any implementation agent runs.
A2  Grading uses CRAP and mutation score on functions the change touched, not advice alone.
A3  Boy-scout cleanup stays inside files the pull request already touches.
A4  One reason to change per module; seams at boundaries for gradual migration.
A5  Full rewrite only when seams cannot carry the migration.
A6  The chain is a work in progress, not a finished method.
A7  This skill does not merge. Landing stays a human act.
```

**Mission:** Run the chain with checkable scores on touched code, or emit the card that says which step is missing.

Robert C. Martin describes this agent chain as work in progress. Adapted here; not copied from his books.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| New behavior, refactor, or feature with a written spec | Activate |
| Need CRAP or mutation score on a change | Activate |
| Boy-scout cleanup without touching quiet files | Activate |
| The invariant belongs in a compiler check or type | Skip. Run that check. Use `trust-stack` to place it. |
| Playbook pick only | Skip. Use installed pstack or `pstack-map`. |
| Machine placement | Skip. That is `split-machine`. |

Slash: `/craft`.

---

## Instructions

1. Read the human spec. If there is no spec, stop and ask for one checkable sentence.
2. **Acceptance (required before coder).** Write Gherkin and a QA acceptance procedure from the spec. No implementation agent runs until both exist. See [references/acceptance.md](references/acceptance.md).
3. **Coder.** Implement unit tests and production code for the story. Make acceptance examples executable where cheap. Do not boy-scout files outside the change set.
4. **Cleaner.** On each function this change touched, run `craft/bin/crap-score.py` with `--max` from [references/thresholds.md](references/thresholds.md). Split or cover until CRAP passes. Rename unclear symbols. Boy-scout only inside touched files.
5. **Hardener.** On the same touched functions, run `craft/bin/mutation-score.py` with `--min` from thresholds. Add tests until the mutation score passes.
6. **QA.** Turn the acceptance procedure into a deterministic script and run it.
7. Emit the Craft card. Hand to `trust-stack` if a repeated miss should become a repo check.

### Neighbors

| Need | Who owns it |
|------|-------------|
| Which playbook or house row | installed pstack or `pstack-map` |
| Which layer holds the invariant | `trust-stack` |
| Which machine runs the job | `split-machine` |
| Hubris or overbuild smell | `odysseus-navigator` |

---

## Emit (required)

```markdown
## Craft
| Field | Value |
|-------|--------|
| **spec** | one sentence from the human |
| **acceptance** | written before coder: yes \| no |
| **step** | acceptance · coder · cleaner · hardener · qa · done |
| **touched** | files or functions in scope |
| **crap_max** | highest CRAP on touched functions, or missing |
| **mutation** | score on touched functions, or missing |
| **scout** | touched files only \| violated |
| **next** | one command or edit |
```

---

## Done when

- Acceptance existed before coder output
- CRAP and mutation thresholds met on touched functions, or the card says which command failed
- Boy-scout stayed inside touched files
- Chain cited as work in progress
- No merge, no push

## Limitations

- Not a router, merge bot, or book summary.
- CRAP and mutation tools here target Python fixtures and touched Python modules. Other languages need an equivalent runner.
- Does not impose line-by-line human TDD on agents; it does require acceptance-from-spec-first and measured cleaner and hardener steps.
