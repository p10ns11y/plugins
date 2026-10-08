#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if ! NODE_PATH="${NODE_PATH:-}" node --input-type=module -e "import { loadTypeScript } from '${ROOT}/bin/js-score-lib.mjs'; if (!loadTypeScript(process.cwd())) process.exit(1)"; then
  npm install --prefix "$tmp" typescript@5.9.3 --no-fund --no-audit
  export NODE_PATH="$tmp/node_modules${NODE_PATH:+:$NODE_PATH}"
fi
command -v rustup >/dev/null 2>&1 && rustup component add llvm-tools
node --test "$ROOT/test/js-score.test.mjs" "$ROOT/test/native-crap.test.mjs"
if command -v cargo >/dev/null 2>&1; then
  CARGO_TARGET_DIR="${TMPDIR:-/tmp}/craft-rust-crap" cargo test --manifest-path "$ROOT/bin/rust-crap/Cargo.toml" --quiet
fi
