#!/usr/bin/env python3
"""Check that relative markdown links and images point at files in this repo."""

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMES = ("http", "https", "mailto", "ftp")


def markdown_files(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [name for name in dirnames if name != ".git"]
        for name in filenames:
            if name.endswith(".md"):
                yield Path(dirpath) / name


def link_targets(text: str):
    start = 0
    while True:
        found = text.find("](", start)
        if found < 0:
            return
        end = text.find(")", found + 2)
        if end < 0:
            return
        line = text.count("\n", 0, found) + 1
        yield line, text[found + 2 : end]
        start = end + 1


def kind(href: str) -> str:
    if href == "":
        return "empty"
    if href.startswith("#"):
        return "fragment"
    head = href.split("/", 1)[0].split("?", 1)[0].split("#", 1)[0]
    scheme = head[:-1].lower() if head.endswith(":") else ""
    if scheme in SCHEMES:
        return "external"
    return "relative"


def stripped(href: str) -> str:
    path = href.split("#", 1)[0].split("?", 1)[0]
    return path


def exists(md_path: Path, href: str) -> bool:
    path = stripped(href)
    target = md_path.parent / path
    if path.endswith("/"):
        return target.is_dir()
    return target.exists()


def main() -> int:
    misses = []
    for md_path in markdown_files(ROOT):
        text = md_path.read_text(encoding="utf-8", errors="surrogateescape")
        rel = md_path.relative_to(ROOT).as_posix()
        for line, href in link_targets(text):
            if kind(href) != "relative":
                continue
            if not exists(md_path, href):
                misses.append(f"{rel}:{line} {href}")
    for miss in misses:
        print(miss)
    return 1 if misses else 0


if __name__ == "__main__":
    sys.exit(main())
