#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKET_NAME = "p10ns11y-plugins"
OWNER = {"name": "p10ns11y"}
PRODUCTIVITY = {"premflow", "uncertainty-laws"}


def plugins():
    found = []
    for path in sorted(ROOT.iterdir()):
        manifest = path / "plugin.json"
        if not path.is_dir() or not manifest.is_file():
            continue
        data = json.loads(manifest.read_text())
        if data.get("name") != path.name:
            raise SystemExit(f"{manifest} name does not match its directory")
        found.append((path.name, data, path))
    if not found:
        raise SystemExit("no plugin directories")
    return found


def dumps(obj):
    return json.dumps(obj, indent=2, ensure_ascii=False) + "\n"


def grok_entry(name, data):
    entry = {
        "name": name,
        "description": data["description"],
        "category": "productivity" if name in PRODUCTIVITY else "development",
        "source": {"type": "local", "path": f"./{name}"},
    }
    if data.get("homepage"):
        entry["homepage"] = data["homepage"]
    if data.get("keywords"):
        entry["keywords"] = data["keywords"]
    return entry


def claude_entry(name, data):
    return {
        "name": name,
        "description": data["description"],
        "source": f"./{name}",
    }


def cursor_market_entry(name, data):
    return {
        "name": name,
        "source": name,
        "description": data["description"],
    }


def cursor_plugin(name, data, path):
    entry = {
        "name": name,
        "version": data["version"],
        "description": data["description"],
    }
    if data.get("author"):
        entry["author"] = data["author"]
    for key in ("homepage", "repository", "license", "keywords"):
        if data.get(key):
            entry[key] = data[key]
    for comp in ("skills", "agents", "commands"):
        if (path / comp).is_dir():
            entry[comp] = f"./{comp}/"
    if (path / "cursor" / "hooks" / "hooks.json").is_file():
        entry["hooks"] = "./cursor/hooks/hooks.json"
    return entry


def documents(items):
    names = [name for name, _, _ in items]
    description = "Grok Build plugins: " + ", ".join(names)
    files = {
        ROOT / ".grok-plugin" / "marketplace.json": dumps(
            {
                "name": MARKET_NAME,
                "description": description,
                "owner": OWNER,
                "plugins": [grok_entry(name, data) for name, data, _ in items],
            }
        ),
        ROOT / ".claude-plugin" / "marketplace.json": dumps(
            {
                "name": MARKET_NAME,
                "owner": OWNER,
                "plugins": [claude_entry(name, data) for name, data, _ in items],
            }
        ),
        ROOT / ".cursor-plugin" / "marketplace.json": dumps(
            {
                "name": MARKET_NAME,
                "owner": OWNER,
                "metadata": {"description": description},
                "plugins": [cursor_market_entry(name, data) for name, data, _ in items],
            }
        ),
    }
    for name, data, path in items:
        text = dumps(cursor_plugin(name, data, path))
        # craft/test/test-thin.sh counts newlines and sits on its cap.
        if name == "craft":
            text = json.dumps(cursor_plugin(name, data, path), separators=(",", ":"), ensure_ascii=False)
        files[path / ".cursor-plugin" / "plugin.json"] = text
    return files


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    files = documents(plugins())
    if args.check:
        drifted = [
            path.relative_to(ROOT).as_posix()
            for path, text in files.items()
            if not path.is_file() or path.read_text() != text
        ]
        if drifted:
            print("catalog drift: " + ", ".join(drifted), file=sys.stderr)
            return 1
        print(f"{len(files)} catalogs match")
        return 0
    for path, text in files.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    print(f"wrote {len(files)} catalogs")
    return 0


if __name__ == "__main__":
    sys.exit(main())
