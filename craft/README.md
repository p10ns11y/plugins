# craft

Agent workflow adapted from Robert C. Martin's clean-code and craftsmanship ideas. He describes the chain as a work in progress: write acceptance tests from the spec before any implementation agent runs, then coder, cleaner with CRAP thresholds, hardener with mutation score, then QA from a written procedure.

| Step | Job | Measured check |
|------|-----|----------------|
| Acceptance | Turn the human spec into Gherkin and a QA acceptance procedure | Acceptance files exist before coder output |
| Coder | Unit tests and code for the story | Tests pass |
| Cleaner | Split complex functions, clear names, boy-scout only in touched files | CRAP at or below threshold on touched functions |
| Hardener | Close test gaps | Mutation score at or above threshold on touched functions |
| QA | Run the acceptance procedure as an executable script | Procedure passes |

Default thresholds for agent work: CRAP at most 6 per touched function (he widens the human bar of about 4 for agents), mutation score at least 0.95 on touched Python functions. See [skills/craft/references/thresholds.md](skills/craft/references/thresholds.md).

For playbook routing use installed pstack or `pstack-map`. For verification layers use `trust-stack`.

## Install

```bash
grok plugin install ./craft --trust
# slash: /craft
```

## Run the score checks

From the repo root, on this plugin's fixtures:

```bash
./craft/test/check-scores.sh
```

On Python files you changed in the last commit:

```bash
./craft/bin/crap-score.py --max 6 craft/fixtures/good/lib.py craft/fixtures/good/test_lib.py
./craft/bin/crap-score.py --max 6 --functions discount craft/fixtures/good/lib.py craft/fixtures/good/test_lib.py
./craft/bin/crap-score.py --max 6 --diff HEAD~1..HEAD craft/fixtures/good/lib.py craft/fixtures/good/test_lib.py
./craft/bin/mutation-score.py --min 0.95 craft/fixtures/good/lib.py craft/fixtures/good/test_lib.py
```

`coverage` is required. Without it the tools exit with `coverage missing: pip install coverage`.

See [skills/craft/references/thresholds.md](skills/craft/references/thresholds.md) for the full commands and how coverage is collected.

## Tests

```bash
./craft/test/test-thin.sh
./craft/test/check-scores.sh
./craft/test/check-acceptance-first.sh
```

Attribution: [NOTICE.md](NOTICE.md).
