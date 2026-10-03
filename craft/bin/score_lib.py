import argparse
import ast
import json
import os
import re
import subprocess
import sys
from pathlib import Path

_BRANCH = (ast.If, ast.For, ast.AsyncFor, ast.While, ast.Assert, ast.IfExp)
_COMP = (ast.ListComp, ast.SetComp, ast.DictComp, ast.GeneratorExp)
_NESTED = (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)
def load_functions(path: Path) -> dict[str, ast.AST]:
    found: dict[str, ast.AST] = {}
    def walk(node: ast.AST, prefix: str) -> None:
        for child in ast.iter_child_nodes(node):
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                name = f"{prefix}.{child.name}" if prefix else child.name
                found[name] = child
                walk(child, name)
            elif isinstance(child, ast.ClassDef):
                walk(child, f"{prefix}.{child.name}" if prefix else child.name)
            else:
                walk(child, prefix)
    walk(ast.parse(path.read_text(encoding="utf-8")), "")
    return found
def require_tool(mod: str) -> None:
    try:
        __import__(mod)
    except ImportError:
        print(f"{mod} missing: pip install {mod}", file=sys.stderr)
        raise SystemExit(2)
def cyclomatic(node: ast.AST) -> int:
    score = 1
    def visit(current: ast.AST) -> None:
        nonlocal score
        for child in ast.iter_child_nodes(current):
            if isinstance(child, _NESTED):
                continue
            if isinstance(child, _BRANCH) or isinstance(child, (ast.ExceptHandler, ast.match_case)):
                score += 1
            elif isinstance(child, ast.BoolOp):
                score += len(child.values) - 1
            elif isinstance(child, _COMP):
                score += len(child.generators) + sum(len(gen.ifs) for gen in child.generators)
            visit(child)
    visit(node)
    return score
def crap(comp: float, cov: float) -> float:
    return (comp ** 2) * ((1 - cov) ** 3) + comp
def statement_lines(node: ast.AST) -> set[int]:
    body = list(getattr(node, "body", None) or [])
    skip: set[int] = set()
    if not body or getattr(body[0], "lineno", None) != node.lineno:
        skip.add(node.lineno)
    for dec in getattr(node, "decorator_list", []):
        skip.update(range(dec.lineno, (dec.end_lineno or dec.lineno) + 1))
    first = body[0] if body else None
    value = getattr(first, "value", None)
    if isinstance(first, ast.Expr) and isinstance(value, ast.Constant) and isinstance(value.value, str):
        skip.update(range(first.lineno, (first.end_lineno or first.lineno) + 1))
    lines: set[int] = set()
    def take(current: ast.AST) -> None:
        for child in ast.iter_child_nodes(current):
            if isinstance(child, _NESTED):
                continue
            if hasattr(child, "lineno"):
                lines.update(range(child.lineno, (getattr(child, "end_lineno", None) or child.lineno) + 1))
            take(child)
    take(node)
    return lines - skip
def pytest_env(lib: Path, cov_file: Path | None) -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(lib.parent)
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    if cov_file is None:
        env.pop("COVERAGE_FILE", None)
    else:
        env["COVERAGE_FILE"] = str(cov_file)
    return env
def run_coverage_json(lib: Path, test: Path, cov_file: Path) -> tuple[dict, set[tuple[int, int]]]:
    env = pytest_env(lib, cov_file)
    cmd = [sys.executable, "-m", "coverage", "run", "--branch", "-m", "pytest", "-q", "-p", "no:cacheprovider", str(test)]
    proc = subprocess.run(cmd, cwd=lib.parent, env=env, capture_output=True, text=True)
    if proc.returncode != 0:
        print("coverage suite failed", file=sys.stderr)
        raise SystemExit(2)
    from coverage.data import CoverageData
    measured = CoverageData(basename=str(cov_file))
    measured.read()
    arc_file = next(path for path in measured.measured_files() if Path(path).name == lib.name)
    arcs = set(measured.arcs(arc_file) or ())
    out = cov_file.with_suffix(".json")
    proc = subprocess.run(
        [sys.executable, "-m", "coverage", "json", "-o", str(out), "--include", lib.name],
        cwd=lib.parent, env=env, capture_output=True, text=True,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr or proc.stdout)
        raise SystemExit(2)
    return json.loads(out.read_text(encoding="utf-8")), arcs
def function_coverage(lib: Path, functions: dict[str, ast.AST], data: dict, arcs: set[tuple[int, int]]) -> dict[str, float]:
    files = data.get("files", {})
    entry = files.get(str(lib.resolve())) or next(v for p, v in files.items() if Path(p).name == lib.name)
    executed = set(entry.get("executed_lines", []))
    tracked = executed | set(entry.get("missing_lines", []))
    out: dict[str, float] = {}
    for name, node in functions.items():
        body = getattr(node, "body", None) or []
        same = bool(body) and getattr(body[0], "lineno", None) == node.lineno
        stmt = statement_lines(node) & tracked
        if same and (-node.lineno, node.lineno) not in arcs:
            out[name] = 0.0
        else:
            out[name] = (len(executed & stmt) / len(stmt)) if stmt else 0.0
    return out
def diff_changed_lines(lib: Path, git_range: str) -> set[int]:
    proc = subprocess.run(
        ["git", "-C", str(lib.parent), "diff", "-U0", git_range, "--", lib.name],
        capture_output=True, text=True, check=False,
    )
    if proc.returncode != 0:
        print((proc.stderr or proc.stdout).strip() or f"git diff failed ({proc.returncode})", file=sys.stderr)
        raise SystemExit(2)
    lines: set[int] = set()
    cur = None
    for raw in proc.stdout.splitlines():
        if raw.startswith("@@"):
            match = re.search(r"\+(\d+)(?:,(\d+))?", raw)
            cur = int(match.group(1)) if match and int(match.group(2) or "1") else None
            continue
        if cur is None or raw.startswith(("+++", "---")):
            continue
        if raw.startswith("+"):
            lines.add(cur)
        if raw[:1] in "+ ":
            cur += 1
    return lines
def functions_for_lines(functions: dict[str, ast.AST], lines: set[int]) -> set[str]:
    hit = [
        name for name, node in functions.items()
        if any(node.lineno <= ln <= (node.end_lineno or node.lineno) for ln in lines)
    ]
    return {name for name in hit if not any(other.startswith(name + ".") for other in hit)}
def resolve_targets(lib, functions, names, git_range):
    if names:
        missing = [name for name in names if name not in functions]
        if missing:
            print(f"unknown functions: {', '.join(missing)}", file=sys.stderr)
            raise SystemExit(2)
        return "functions", set(names)
    if git_range:
        hit = functions_for_lines(functions, diff_changed_lines(lib, git_range))
        if not hit:
            print(f"no touched functions in {lib.name}", file=sys.stderr)
            raise SystemExit(2)
        return "diff", hit
    return "file", set(functions)
def prepare(desc: str, flag: str, default: float):
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument("lib")
    parser.add_argument("test")
    parser.add_argument(flag, dest="limit", type=float, default=default)
    parser.add_argument("--functions")
    parser.add_argument("--diff", dest="git_range")
    args = parser.parse_args()
    lib, test = Path(args.lib).resolve(), Path(args.test).resolve()
    if not lib.is_file():
        print(f"missing {lib}", file=sys.stderr)
        raise SystemExit(2)
    functions = load_functions(lib)
    if not functions:
        print(f"no functions in {lib.name}", file=sys.stderr)
        raise SystemExit(2)
    names = [part.strip() for part in args.functions.split(",")] if args.functions else None
    scope, targets = resolve_targets(lib, functions, names, args.git_range)
    return args, lib, test, functions, scope, targets
def print_scope(scope: str, targets: set[str]) -> None:
    print("scope=file" if scope == "file" else f"scope={scope} functions={','.join(sorted(targets))}")
