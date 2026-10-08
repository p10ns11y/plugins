# craft

Specifier, coder, cleaner, hardener, then QA.
Robert C. Martin with Matt Pocock, 19 Aug 2026: [LIVE: Uncle Bob on Software Fundamentals in the Age of AI](https://www.youtube.com/watch?v=zcLPGC-tvgk).

| Order | Role | Output | Check |
|-------|------|--------|-------|
| 1 | Specifier | Gherkin, a QA procedure, and optional LAWS.bend | A .feature file, or a file under features/ or qa/, exists before the first production commit. LAWS.bend counts as acceptance. |
| 2 | Coder | Unit tests, the implementation, and PROOF.bend | When LAWS.bend exists, bend --verdict PROOF.bend prints ALL PROOFS CHECK |
| 3 | Cleaner | Smaller functions and clearer names | CRAP on touched functions, then a general review. Boy-scout cleanup stays inside the touched files. That limit is our house rule, not his. |
| 4 | Hardener | Tests that kill surviving mutants | Mutation score on touched non-Bend functions |
| 5 | QA | The QA procedure as a script | The script passes |

Commands and numbers: [skills/craft/references/thresholds.md](skills/craft/references/thresholds.md). CRAP uses `coverage`. Mutation score does not. TypeScript files use `crap-score.mjs` and `mutation-score.mjs`. Attribution: [NOTICE.md](NOTICE.md).

## Install

`grok plugin install ./craft --trust`. Slash command: `/craft`.

## Tests

`./craft/test/test-thin.sh`, `./craft/test/check-scores.sh`, `./craft/test/check-acceptance-first.sh`, `./craft/test/check-proof.sh`

Bend 2.0.35 and Lean v4.34.0. Bend covers pure transitions only, not IO or timing.
