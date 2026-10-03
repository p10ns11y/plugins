#!/usr/bin/env python3
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from score_lib import crap, cyclomatic, function_coverage, prepare, print_scope, require_tool, run_coverage_json


def main() -> int:
    args, lib, test, functions, scope, targets = prepare("CRAP score for Python functions", "--max", 6.0)
    require_tool("coverage")
    with tempfile.TemporaryDirectory() as tmp:
        data, arcs = run_coverage_json(lib, test, Path(tmp) / ".coverage")
    cov = function_coverage(lib, functions, data, arcs)
    print_scope(scope, targets)
    worst, worst_name = 0.0, ""
    for name in sorted(targets):
        comp = float(cyclomatic(functions[name]))
        seen = cov.get(name, 0.0)
        score = crap(comp, seen)
        print(f"{name}: comp={comp:.0f} cov={seen:.2f} crap={score:.2f}")
        if score > worst:
            worst, worst_name = score, name
    print(f"worst={worst_name} crap_max={worst:.2f} threshold={args.limit:g}")
    return 0 if worst <= args.limit else 1


if __name__ == "__main__":
    raise SystemExit(main())
