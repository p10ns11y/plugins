#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if ! NODE_PATH="${NODE_PATH:-}" node --input-type=module -e "import { loadTypeScript } from '${ROOT}/bin/js-score-lib.mjs'; if (!loadTypeScript(process.cwd())) process.exit(1)"; then
  npm install --prefix "$tmp" typescript@5.9.3 --no-fund --no-audit
  export NODE_PATH="$tmp/node_modules${NODE_PATH:+:$NODE_PATH}"
fi
node --test "$ROOT/test/js-score.test.mjs"
