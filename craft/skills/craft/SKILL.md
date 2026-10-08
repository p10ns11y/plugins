---
name: craft
version: 0.1.0
description: >
  Specifier, coder, cleaner, hardener, QA. CRAP on touched functions;
  mutation testing by the hardener. Optional LAWS.bend. PROOF.bend imports it.
  Use for /craft, CRAP, mutation score, or a Bend proof.
---

# craft

```text
A1  The specifier writes Gherkin, a QA procedure, and optional LAWS.bend before a coder runs.
A2  CRAP and mutation score come from the tools, on functions the change touched.
A3  Boy-scout cleanup stays inside the touched files.
A4  One reason to change per module. A full rewrite waits until a seam cannot carry the move.
A5  This skill does not merge.
```

## Steps

1. Specifier. [references/acceptance.md](references/acceptance.md).
2. Coder. Unit tests and the implementation. When LAWS.bend exists, write PROOF.bend that imports it, then run `craft/test/check-proof.sh`. Exit 2 means bend is missing. Report a hole. Do not weaken the law.
3. Cleaner. `crap-score.py` for Python. `crap-score.mjs` for TypeScript, and that command dispatches Rust to the Rust runner and C or C++ to clang plus gcov. `--max` is in [references/thresholds.md](references/thresholds.md).
4. Hardener. `mutation-score.py` for Python, or `mutation-score.mjs` for TypeScript, with `--min` from the same page, on non-Bend code.
5. QA. Run the procedure as a script.
6. Emit the card.

## Neighbors

| Need | Who |
|------|-----|
| Playbook or the house row | installed pstack or `pstack-map` |
| Which layer holds an invariant | `trust-stack` |
| Which machine runs the job | `split-machine` |

## Emit (required)

```markdown
## Craft
| Field | Value |
|-------|--------|
| **spec** | |
| **acceptance** | written before coder: yes \| no |
| **step** | specifier · coder · cleaner · hardener · qa · done |
| **touched** | |
| **crap_max** | |
| **mutation** | |
| **scout** | touched files only \| violated |
| **next** | |
```

## Done when

Acceptance existed before the first production edit. CRAP and mutation on the touched functions meet the thresholds, or the card names the command that failed. When LAWS.bend exists, `craft/test/check-proof.sh` prints ALL PROOFS CHECK. Scout stayed inside touched files. No merge.
