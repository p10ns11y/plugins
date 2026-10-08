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

`scope=file` scores every function. `--functions` and `--diff` score the named or touched functions. A bad `--diff` range prints the git error and exits 2. Zero mutants exits 2. See [README](../../../README.md).

TypeScript and JavaScript use the same flags:

```bash
node craft/bin/crap-score.mjs --max 6 path/to/lib.ts path/to/test.ts
node craft/bin/mutation-score.mjs --min 0.95 path/to/lib.ts path/to/test.ts
```

Coverage comes from vitest. Mutation comes from Stryker. `--report path` scores a saved Stryker JSON and does not run the suite. A missing typescript, vitest, or stryker install exits 2.

Rust, C, and C++ use the same CRAP flags through `crap-score.mjs`, which only dispatches. The Rust runner parses Rust and reads llvm-cov. C and C++ complexity comes from clang's AST and coverage comes from gcov. The Rust test names the library crate after the library file. A missing cargo, rustc, clang, or gcc exits 2.

```bash
node craft/bin/crap-score.mjs --max 6 path/to/lib.c path/to/test.c
node craft/bin/crap-score.mjs --max 6 path/to/lib.cpp path/to/test.cpp
node craft/bin/crap-score.mjs --max 6 path/to/lib.rs path/to/test.rs
```
