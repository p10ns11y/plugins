#!/usr/bin/env python3
import argparse
import ast
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from score_lib import function_coverage, load_functions, require_coverage, resolve_targets, run_coverage_json


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


def main() -> int:
    p = argparse.ArgumentParser(description="CRAP score for Python functions")
    p.add_argument("lib")
    p.add_argument("test")
    p.add_argument("--max", type=float, default=6.0)
    p.add_argument("--functions", help="comma-separated function names")
    p.add_argument("--diff", dest="git_range", help="git revision range")
    args = p.parse_args()
    lib = Path(args.lib).resolve()
    test = Path(args.test).resolve()
    names = [s.strip() for s in args.functions.split(",")] if args.functions else None
    functions = load_functions(lib)
    scope, targets = resolve_targets(lib, functions, names, args.git_range)
    require_coverage()
    with tempfile.TemporaryDirectory() as tmp:
        cov_file = Path(tmp) / ".coverage"
        data = run_coverage_json(lib, test, cov_file)
    cov = function_coverage(lib, functions, data)
    if scope == "file":
        print("scope=file")
    else:
        print(f"scope={scope} functions={','.join(sorted(targets))}")
    worst = 0.0
    worst_name = ""
    for name in sorted(targets):
        node = functions[name]
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
