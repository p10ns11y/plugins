#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
dest="${HOME}/.cursor/skills"
mkdir -p "$dest"
shopt -s nullglob
for skill in "$root"/*/skills/*/SKILL.md; do
  src="$(dirname "$skill")"
  name="$(basename "$src")"
  rm -rf "${dest:?}/${name}"
  cp -a "$src" "${dest}/${name}"
done
