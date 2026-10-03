# Chain (work in progress)

Robert C. Martin describes this multi-agent chain as work in progress, not a finished method. Adapted here for coding agents.

| Order | Role | Output | Check |
|-------|------|--------|-------|
| 1 | Acceptance | Gherkin + QA procedure from the human spec | Written before any coder agent runs |
| 2 | Coder | Unit tests + implementation | Tests green |
| 3 | Cleaner | Smaller functions, clear names, boy-scout in touched files only | CRAP at or below threshold on touched functions |
| 4 | Hardener | Extra tests where mutants survive | Mutation score at or above threshold on touched functions |
| 5 | QA | Executable acceptance script | Procedure passes |

Each step is a fresh context when possible so trajectory from implementation does not leak into hardening.

Deterministic tools loop: change code until the score check passes. That is the required check, not a long steering document at the top of the prompt.
