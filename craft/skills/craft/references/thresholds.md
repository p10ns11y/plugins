# Thresholds

CRAP combines cyclomatic complexity and automated line coverage:

`CRAP(m) = comp(m)^2 * (1 - cov(m))^3 + comp(m)`

| Audience | CRAP max per touched function | Notes |
|----------|-------------------------------|-------|
| Human-oriented bar | 4 | Martin's rough human target in the talk |
| Agent work (default) | 6 | He widens the bar for agents while searching for the limit |

Mutation score = killed mutants / total mutants on touched functions. Default minimum for agent work: **0.95**.

## Commands (Python touched code)

Collect coverage and CRAP:

```bash
python3 craft/bin/crap-score.py --max 6 path/to/lib.py path/to/test_lib.py
python3 craft/bin/crap-score.py --max 6 --functions discount,apply path/to/lib.py path/to/test_lib.py
python3 craft/bin/crap-score.py --max 6 --diff HEAD~1..HEAD path/to/lib.py path/to/test_lib.py
```

Mutation score:

```bash
python3 craft/bin/mutation-score.py --min 0.95 path/to/lib.py path/to/test_lib.py
python3 craft/bin/mutation-score.py --min 0.95 --functions discount path/to/lib.py path/to/test_lib.py
python3 craft/bin/mutation-score.py --min 0.95 --diff HEAD~1..HEAD path/to/lib.py path/to/test_lib.py
```

Without `--functions` or `--diff`, output includes `scope=file`. Scoped runs list the touched functions. `coverage` is required; if missing the tool exits with `coverage missing: pip install coverage`.

Run all fixture checks:

```bash
./craft/test/check-scores.sh
```

Acceptance-before-coder on a git range:

```bash
./craft/test/check-acceptance-first.sh HEAD~1..HEAD
```
