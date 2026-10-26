# ub-mode: red test first

For every `feature` and `bug-fix` role:

1. Write the test that shows the missing behaviour or the bug.
2. Run it and see it fail for the right reason.
3. Commit the test alone. The commit body carries `proof:` with the command and the failing result.
4. Write the code until the test passes. Commit it with `proof:` showing the pass.

A test-only commit changes test files and nothing else (paths under `test/`, `tests/`, `fixtures/`, `testdata/`, or `test-*`, `*_test.*`, `*.test.*`, `*.spec.*`).

CI checks this with `scripts/ci/check-red-first.mjs`: in a pull request that changes code, a test-only commit must come before the first commit that changes code. Pull requests that change only docs or config pass.
