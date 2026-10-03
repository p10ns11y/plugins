#!/usr/bin/env python3
import argparse
import ast
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def cyclomatic(node: ast.AST) -> int:
    score = 1
    for child in ast.walk(node):
        if isinstance(child, (ast.If, ast.For, ast.While, ast.Try, ast.With, ast.Assert)):
            score += 1
        elif isinstance(child, ast.BoolOp):
            score += max(0, len(child.values) - 1)
        elif isinstance(child, (ast.ListComp, ast.SetComp, ast.DictComp, ast.GeneratorExp)):
            score += 1
    return score


def crap(comp: float, cov: float) -> float:
    return (comp ** 2) * ((1 - cov) ** 3) + comp


def load_functions(path: Path) -> dict[str, ast.FunctionDef]:
    tree = ast.parse(path.read_text())
    return {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef)}


def line_coverage(lib: Path, test: Path) -> dict[str, float]:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(lib.parent)
    with tempfile.TemporaryDirectory() as tmp:
        cov_file = Path(tmp) / ".coverage"
        env["COVERAGE_FILE"] = str(cov_file)
        try:
            subprocess.run(
                [sys.executable, "-m", "coverage", "run", "-m", "pytest", "-q", str(test)],
                check=True,
                cwd=lib.parent,
                env=env,
                capture_output=True,
            )
            report = subprocess.run(
                [sys.executable, "-m", "coverage", "report", "-m", "--include", lib.name],
                check=True,
                cwd=lib.parent,
                env=env,
                capture_output=True,
                text=True,
            )
            stmt = 0
            miss = 0
            for line in report.stdout.splitlines():
                if not line.strip().startswith(str(lib.name)):
                    continue
                parts = line.split()
                if len(parts) >= 4:
                    stmt = int(parts[1])
                    miss = int(parts[2])
            ratio = 1.0 if stmt == 0 else (stmt - miss) / stmt
            return {name: ratio for name in load_functions(lib)}
        except (subprocess.CalledProcessError, FileNotFoundError):
            subprocess.run(
                [sys.executable, "-m", "pytest", "-q", str(test)],
                check=True,
                cwd=lib.parent,
                env=env,
                capture_output=True,
            )
            return {name: 1.0 for name in load_functions(lib)}


def main() -> int:
    p = argparse.ArgumentParser(description="CRAP score for Python functions")
    p.add_argument("lib")
    p.add_argument("test")
    p.add_argument("--max", type=float, default=6.0)
    args = p.parse_args()
    lib = Path(args.lib).resolve()
    test = Path(args.test).resolve()
    cov = line_coverage(lib, test)
    worst = 0.0
    worst_name = ""
    for name, node in load_functions(lib).items():
        comp = float(cyclomatic(node))
        score = crap(comp, cov.get(name, 0.0))
        print(f"{name}: comp={comp:.0f} cov={cov.get(name, 0.0):.2f} crap={score:.2f}")
        if score > worst:
            worst = score
            worst_name = name
    print(f"worst={worst_name} crap_max={worst:.2f} threshold={args.max}")
    return 0 if worst <= args.max else 1


if __name__ == "__main__":
    raise SystemExit(main())
