#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path


REPLACEMENTS = [
    (" + ", " - "),
    (" - ", " + "),
    (" == ", " != "),
    (" != ", " == "),
    (" < ", " > "),
    (" > ", " < "),
    ("return ", "return 0  # "),
]


def mutants(source: str) -> list[str]:
    out: list[str] = []
    lines = source.splitlines()
    for i, line in enumerate(lines):
        if line.strip().startswith("#") or "def " in line:
            continue
        for old, new in REPLACEMENTS:
            if old in line:
                patched = lines[:]
                patched[i] = line.replace(old, new, 1)
                out.append("\n".join(patched) + "\n")
    return out


def run_tests(lib_dir: Path, lib_name: str, test: Path) -> bool:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(lib_dir)
    proc = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", str(test)],
        cwd=lib_dir,
        env=env,
        capture_output=True,
    )
    return proc.returncode == 0


def main() -> int:
    p = argparse.ArgumentParser(description="Simple mutation score for Python")
    p.add_argument("lib")
    p.add_argument("test")
    p.add_argument("--min", type=float, default=0.95)
    args = p.parse_args()
    lib = Path(args.lib).resolve()
    test = Path(args.test).resolve()
    source = lib.read_text()
    muts = mutants(source)
    if not muts:
        print("mutation_score=1.00 mutants=0 killed=0")
        return 0
    killed = 0
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        tmp_lib = tmp_dir / lib.name
        tmp_test = tmp_dir / test.name
        tmp_test.write_text(test.read_text())
        for patched in muts:
            tmp_lib.write_text(patched)
            if not run_tests(tmp_dir, lib.name, tmp_test):
                killed += 1
    total = len(muts)
    score = killed / total
    print(f"mutation_score={score:.2f} mutants={total} killed={killed} threshold={args.min}")
    return 0 if score >= args.min else 1


if __name__ == "__main__":
    raise SystemExit(main())
