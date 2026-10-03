# Acceptance before coder

Acceptance tests come from the spec, written before any implementation agent runs. Otherwise grading favors whichever agent wrote the tests.

## Required outputs

1. **Gherkin** — given/when/then examples the human can read, derived from the spec, not from implementation guesses.
2. **QA procedure** — steps a human would take at the UI or API boundary to prove the story works.

Store them where the repo keeps specs, for example `features/<story>.feature` and `qa/<story>.md`.

## Precondition check

Before starting the coder step, confirm:

- Gherkin file timestamp or commit is not after the first production edit for this story.
- The QA procedure names observable outcomes from the spec.

Run `craft/test/check-acceptance-first.sh` on the branch when the repo uses git.

## Coder handoff

The coder receives: spec, Gherkin, QA procedure. The coder does not invent acceptance criteria. Unit tests may be written function-by-function; acceptance criteria are already fixed.
