# Thresholds

`CRAP(m) = comp(m)^2 * (1 - cov(m))^3 + comp(m)` with line coverage.

| Who | CRAP per touched function |
|-----|---------------------------|
| Humans | below four (below 4), 0:32:52 |
| Agents | 6, maybe 8, 0:32:58 |

Robert C. Martin's chain is specifier, coder, cleaner, hardener, then QA. Our default mutation minimum is 0.95. He aims the hardener at full coverage (0:21:57).

CRAP needs `coverage` and exits 2 with `coverage missing: pip install coverage` when it is absent. Mutation score exits 2 with `pytest missing: pip install pytest` when pytest is absent.

## Commands

```bash
python3 craft/bin/crap-score.py --max 6 path/to/lib.py path/to/test_lib.py
python3 craft/bin/crap-score.py --max 6 --functions discount path/to/lib.py path/to/test_lib.py
python3 craft/bin/crap-score.py --max 6 --diff HEAD~1..HEAD path/to/lib.py path/to/test_lib.py
python3 craft/bin/mutation-score.py --min 0.95 path/to/lib.py path/to/test_lib.py
python3 craft/bin/mutation-score.py --min 0.95 --functions discount path/to/lib.py path/to/test_lib.py
python3 craft/bin/mutation-score.py --min 0.95 --diff HEAD~1..HEAD path/to/lib.py path/to/test_lib.py
./craft/test/check-acceptance-first.sh HEAD~1..HEAD
```

`scope=file` scores every function. `--functions` and `--diff` score the named or touched functions. A bad `--diff` range prints the git error and exits 2. Zero mutants exits 2.
