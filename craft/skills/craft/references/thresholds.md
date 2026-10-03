# Thresholds

| Who | CRAP per touched function |
|-----|---------------------------|
| Humans | below 4 |
| Agents | 6 (try 8 at most) |

Default mutation minimum is 0.95; aim the hardener at full coverage.

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
./craft/test/check-proof.sh path/to/dir
```

`scope=file` scores every function. `--functions` and `--diff` score the named or touched functions. A bad `--diff` range prints the git error and exits 2. Zero mutants exits 2. Bend 2.0.35 and Lean v4.34.0. `check-proof.sh` runs `bend --verdict PROOF.bend` and exits 2 when bend is missing.
