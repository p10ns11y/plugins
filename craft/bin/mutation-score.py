#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from score_lib import load_functions, resolve_targets

REPLACEMENTS = [
    (" + ", " - "),
    (" - ", " + "),
    (" == ", " != "),
    (" != ", " == "),
    (" < ", " > "),
    (" > ", " < "),
    ("return ", "return 0  # "),
]


def mutants_for_targets(source: str, functions: dict, targets: set[str]) -> dict[str, list[str]]:
    lines = source.splitlines()
    spans = {
        name: (fn.lineno, fn.end_lineno or fn.lineno)
        for name, fn in functions.items()
        if name in targets
    }
    out: dict[str, list[str]] = {name: [] for name in targets}
    for i, line in enumerate(lines):
        line_no = i + 1
        owner = None
        for name, (start, end) in spans.items():
            if start <= line_no <= end:
                owner = name
                break
        if not owner or line.strip().startswith("#") or "def " in line:
            continue
        for old, new in REPLACEMENTS:
            if old in line:
                patched = lines[:]
                patched[i] = line.replace(old, new, 1)
                out[owner].append("\n".join(patched) + "\n")
    return out


def run_tests(lib_dir: Path, test: Path) -> bool:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(lib_dir)
    proc = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", str(test)],
        cwd=lib_dir,
        env=env,
        capture_output=True,
    )
    return proc.returncode == 0


def score_mutants(muts: list[str], lib_name: str, test: Path) -> tuple[int, int, float]:
    if not muts:
        return 0, 0, 1.0
    killed = 0
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        tmp_lib = tmp_dir / lib_name
        tmp_test = tmp_dir / test.name
        tmp_test.write_text(test.read_text())
        for patched in muts:
            tmp_lib.write_text(patched)
            if not run_tests(tmp_dir, tmp_test):
                killed += 1
    total = len(muts)
    return killed, total, killed / total


def main() -> int:
    p = argparse.ArgumentParser(description="Simple mutation score for Python")
    p.add_argument("lib")
    p.add_argument("test")
    p.add_argument("--min", type=float, default=0.95)
    p.add_argument("--functions", help="comma-separated function names")
    p.add_argument("--diff", dest="git_range", help="git revision range")
    args = p.parse_args()
    lib = Path(args.lib).resolve()
    test = Path(args.test).resolve()
    names = [s.strip() for s in args.functions.split(",")] if args.functions else None
    functions = load_functions(lib)
    scope, targets = resolve_targets(lib, functions, names, args.git_range)
    source = lib.read_text()
    by_fn = mutants_for_targets(source, functions, targets)
    if scope == "file":
        print("scope=file")
    else:
        print(f"scope={scope} functions={','.join(sorted(targets))}")
    all_killed = 0
    all_total = 0
    for name in sorted(targets):
        killed, total, score = score_mutants(by_fn.get(name, []), lib.name, test)
        all_killed += killed
        all_total += total
        print(f"{name}: mutation_score={score:.2f} mutants={total} killed={killed}")
    overall = all_killed / all_total if all_total else 1.0
    print(f"mutation_score={overall:.2f} mutants={all_total} killed={all_killed} threshold={args.min}")
    return 0 if overall >= args.min else 1


if __name__ == "__main__":
    raise SystemExit(main())
