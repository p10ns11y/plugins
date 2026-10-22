#!/usr/bin/env python3
"""bin/route finds pstack-map in the monorepo and in the plugin cache layout."""

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent
MAP = Path("skills") / "pstack-map" / "references" / "map.md"
WHEN = "a bug-fix seen only through the cache"


def fail(msg):
    print("FAIL", msg)
    return 1


def route(root):
    return subprocess.run(
        [sys.executable, str(root / "bin" / "route"), WHEN],
        capture_output=True,
        text=True,
    )


def plugin(dest):
    (dest / "bin").mkdir(parents=True)
    shutil.copy2(ROOT / "bin" / "route", dest / "bin" / "route")
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    row = dict(next(r for r in manifest["primary"] if r.get("route") == "light"), when=WHEN)
    manifest["primary"].append(row)
    (dest / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    return dest


def house(dest, text):
    (dest / MAP).parent.mkdir(parents=True)
    (dest / MAP).write_text(text, encoding="utf-8")


def main():
    errors = 0
    real = (REPO / "pstack-map" / MAP).read_text(encoding="utf-8")
    want = "bug-fix"

    with tempfile.TemporaryDirectory() as tmp:
        cache = Path(tmp) / "cache" / "p10ns11y-plugins"
        root = plugin(cache / "intelli-route" / "0.4.0")

        proc = route(root)
        if proc.returncode != 1 or "missing pstack-map map.md" not in proc.stderr:
            errors += fail("no pstack-map: exit %s %s" % (proc.returncode, proc.stderr.strip()))

        house(cache / "pstack-map" / "0.0.1", "")
        house(cache / "pstack-map" / "0.4.0", real)
        proc = route(root)
        if proc.returncode != 0:
            errors += fail("cache layout exit %s %s" % (proc.returncode, proc.stderr.strip()))
        elif json.loads(proc.stdout)["playbook"] != want:
            errors += fail("cache layout playbook %s want %s" % (proc.stdout.strip(), want))

        flat = plugin(Path(tmp) / "mono" / "intelli-route")
        house(flat.parent / "pstack-map", real)
        proc = route(flat)
        if proc.returncode != 0 or json.loads(proc.stdout)["playbook"] != want:
            errors += fail("monorepo layout %s %s" % (proc.returncode, proc.stderr.strip()))

    if errors:
        print("%s failure(s)" % errors)
        return 1
    print("ok  route layouts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
