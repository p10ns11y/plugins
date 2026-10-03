import ast
import json
import os
import re
import subprocess
import sys
from pathlib import Path


def load_functions(path: Path) -> dict[str, ast.FunctionDef]:
    tree = ast.parse(path.read_text())
    return {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef)}


def require_coverage() -> None:
    try:
        import coverage  # noqa: F401
    except ImportError:
        print("coverage missing: pip install coverage", file=sys.stderr)
        raise SystemExit(2)


def run_coverage_json(lib: Path, test: Path, cov_file: Path) -> dict:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(lib.parent)
    env["COVERAGE_FILE"] = str(cov_file)
    subprocess.run(
        [sys.executable, "-m", "coverage", "run", "-m", "pytest", "-q", str(test)],
        check=True,
        cwd=lib.parent,
        env=env,
        capture_output=True,
    )
    out = cov_file.with_suffix(".json")
    subprocess.run(
        [sys.executable, "-m", "coverage", "json", "-o", str(out), "--include", lib.name],
        check=True,
        cwd=lib.parent,
        env=env,
        capture_output=True,
    )
    return json.loads(out.read_text())


def file_cov_entry(data: dict, lib: Path) -> dict:
    files = data.get("files", {})
    key = str(lib.resolve())
    if key in files:
        return files[key]
    name = lib.name
    for k, v in files.items():
        if k.endswith(name) or Path(k).name == name:
            return v
    raise KeyError(lib)


def function_coverage(lib: Path, functions: dict[str, ast.FunctionDef], data: dict) -> dict[str, float]:
    entry = file_cov_entry(data, lib)
    executed = set(entry.get("executed_lines", []))
    missing = set(entry.get("missing_lines", []))
    out: dict[str, float] = {}
    for name, node in functions.items():
        start = node.lineno
        end = node.end_lineno or start
        stmt = {ln for ln in range(start, end + 1) if ln in executed or ln in missing}
        if not stmt:
            out[name] = 0.0
        else:
            out[name] = len(executed & stmt) / len(stmt)
    return out


def is_test_path(path: str) -> bool:
    p = path.replace("\\", "/")
    base = Path(p).name
    if re.search(r"(^|/)tests?/", p):
        return True
    if base.startswith("test_") and base.endswith(".py"):
        return True
    if base.endswith("_test.py"):
        return True
    if re.search(r"\.(spec|test)\.", base):
        return True
    return False


def is_production_path(path: str) -> bool:
    if not re.search(r"\.(py|js|ts|go|rs|c|cpp)$", path):
        return False
    return not is_test_path(path)


def is_acceptance_path(path: str) -> bool:
    p = path.replace("\\", "/")
    if p.endswith(".feature"):
        return True
    if "/features/" in p or "/qa/" in p:
        return True
    if "acceptance" in p.lower():
        return True
    return False


def diff_changed_lines(lib: Path, git_range: str) -> set[int]:
    proc = subprocess.run(
        ["git", "diff", "-U0", git_range, "--", str(lib)],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode not in (0, 1):
        return set()
    lines: set[int] = set()
    cur: int | None = None
    for raw in proc.stdout.splitlines():
        if raw.startswith("@@"):
            m = re.search(r"\+(\d+)(?:,(\d+))?", raw)
            if not m:
                continue
            cur = int(m.group(1))
            extra = int(m.group(2) or "1")
            if extra == 0:
                cur = None
            continue
        if cur is None:
            continue
        if raw.startswith("+++") or raw.startswith("---"):
            continue
        if raw.startswith("+") and not raw.startswith("++"):
            lines.add(cur)
            cur += 1
        elif raw.startswith("-") and not raw.startswith("--"):
            continue
        elif raw.startswith(" "):
            cur += 1
    return lines


def functions_for_lines(functions: dict[str, ast.FunctionDef], lines: set[int]) -> set[str]:
    hit: set[str] = set()
    for name, node in functions.items():
        start = node.lineno
        end = node.end_lineno or start
        if any(start <= ln <= end for ln in lines):
            hit.add(name)
    return hit


def resolve_targets(
    lib: Path,
    functions: dict[str, ast.FunctionDef],
    names: list[str] | None,
    git_range: str | None,
) -> tuple[str, set[str]]:
    if names:
        missing = [n for n in names if n not in functions]
        if missing:
            print(f"unknown functions: {', '.join(missing)}", file=sys.stderr)
            raise SystemExit(2)
        return "functions", set(names)
    if git_range:
        lines = diff_changed_lines(lib, git_range)
        hit = functions_for_lines(functions, lines)
        if not hit:
            print(f"scope=diff no touched functions in {lib.name}", file=sys.stderr)
            raise SystemExit(2)
        return "diff", hit
    return "file", set(functions)
