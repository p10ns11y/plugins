# Specifier

Robert C. Martin's chain is specifier, coder, cleaner, hardener, then QA. The specifier turns the human spec into Gherkin and a QA procedure before any coder runs (0:20:24).

Our lesson: grading favors whoever wrote the tests, so these files come from the spec.

Store them as `features/<story>.feature` and `qa/<story>.md`.

`craft/test/check-acceptance-first.sh <range>` walks commits from oldest to newest. A `.feature` file, or a file under `features/` or `qa/`, lands with or before the first production file. Acceptance files already at the range base count. Any acceptance edit after production code has been seen fails, whatever else the commit touches. Source files are production, including `src/acceptance_utils.py`, `.tsx`, and `.java`. A test or a source file wins over an acceptance path. Config, data, dotfiles, and extensionless files are neutral.
