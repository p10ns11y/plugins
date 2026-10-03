#!/usr/bin/env python3
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from score_lib import prepare, print_scope, pytest_env, require_tool

REPLACEMENTS = (
    (" + ", " - "), (" - ", " + "), (" == ", " != "), (" != ", " == "),
    (" < ", " > "), (" > ", " < "), ("return ", "return 0  # "),
)

def mutants_for(source: str, functions: dict, targets: set[str]) -> dict[str, list[str]]:
    lines = source.splitlines()
    spans = sorted(
        ( (fn.end_lineno or fn.lineno) - fn.lineno, name, fn.lineno, fn.end_lineno or fn.lineno)
        for name, fn in functions.items() if name in targets
    )
    out: dict[str, list[str]] = {name: [] for name in targets}
    tail = "\n" if source.endswith("\n") else ""
    for index, line in enumerate(lines, start=1):
        owner = next((name for _w, name, start, end in spans if start <= index <= end), None)
        stripped = line.strip()
        if owner is None or not stripped or stripped.startswith("#") or "def " in line:
            continue
        for old, new in REPLACEMENTS:
            if old not in line:
                continue
            patched = lines[:]
            patched[index - 1] = line.replace(old, new, 1)
            text = "\n".join(patched) + tail
            try:
                compile(text, "<mut>", "exec")
            except SyntaxError:
                continue
            out[owner].append(text)
    return out

def run_pytest(cwd: Path, test_name: str, timeout: float | None) -> int:
    cmd = [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", "--tb=no", test_name]
    try:
        proc = subprocess.run(
            cmd, cwd=cwd, env=pytest_env(cwd / "lib.py", None), capture_output=True, text=True, timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return 1
    return proc.returncode

def main() -> int:
    require_tool("pytest")
    args, lib, test, functions, scope, targets = prepare("Mutation score for Python functions", "--min", 0.95)
    by_fn = mutants_for(lib.read_text(encoding="utf-8"), functions, targets)
    rows = []
    killed = total = 0
    with tempfile.TemporaryDirectory() as tmp:
        dest = Path(tmp) / "pkg"
        shutil.copytree(
            lib.parent, dest,
            ignore=shutil.ignore_patterns("__pycache__", ".pytest_cache", ".git", "*.pyc", ".coverage"),
        )
        staged = dest / lib.name
        if test.parent.resolve() != lib.parent.resolve():
            shutil.copyfile(test, dest / test.name)
        started = time.perf_counter()
        if run_pytest(dest, test.name, None) != 0:
            print("unmutated suite failed", file=sys.stderr)
            return 2
        budget = max((time.perf_counter() - started) * 10, 1.0)
        original = lib.read_text(encoding="utf-8")
        for name in sorted(by_fn):
            dead = 0
            for text in by_fn[name]:
                staged.write_text(text, encoding="utf-8")
                dead += run_pytest(dest, test.name, budget) == 1
            staged.write_text(original, encoding="utf-8")
            rows.append((name, dead, len(by_fn[name])))
            killed += dead
            total += len(by_fn[name])
    if total == 0:
        print("no mutants", file=sys.stderr)
        return 2
    print_scope(scope, targets)
    for name, dead, count in rows:
        if count == 0:
            print(f"{name}: mutants=0")
        else:
            print(f"{name}: mutation_score={dead / count:.2f} mutants={count} killed={dead}")
    print(f"mutation_score={killed / total:.2f} mutants={total} killed={killed} threshold={args.limit:g}")
    return 0 if killed / total >= args.limit else 1

if __name__ == "__main__":
    raise SystemExit(main())
