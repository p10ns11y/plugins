#!/usr/bin/env bash
# Thin LCV plugin: algorithm + skill, not a layout engine.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  local p="$1"
  [[ -f "$ROOT/$p" || -d "$ROOT/$p" ]] && ok "exists $p" || bad "missing $p"
}

need plugin.json
need LICENSE
need README.md
need commands/layout-content-view.md
need cursor/commands/layout-content-view.md
need agents/layout-content-view.md
need scripts/lcv.mjs
need scripts/probe-web.mjs
need skills/layout-content-view/SKILL.md
need skills/layout-content-view/references/predicates.md
need skills/layout-content-view/references/sitemap-graph.md
need skills/layout-content-view/references/harness.md
need skills/layout-content-view/references/pilot-devprofile.md
need test/test-predicates.mjs
need test/fixtures/ellipsis.html

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "layout-content-view"' && ok "plugin.json name" || bad "plugin.json name"

skill="$(cat "$ROOT/skills/layout-content-view/SKILL.md")"
echo "$skill" | grep -q 'A1' && ok "skill axioms" || bad "skill missing axioms"
echo "$skill" | grep -qi 'must-show' && ok "skill must-show" || bad "skill missing must-show"
if echo "$skill" | grep -qi 'Prior→Probe→Simulate→Score'; then
  bad "skill inlines EVA"
else
  ok "skill does not inline EVA"
fi
if echo "$skill" | grep -qi 'SURFACES'; then
  ok "skill forbids second SURFACES"
else
  bad "skill missing SURFACES forbid"
fi

if [[ -d "$ROOT/c" ]]; then bad "c/ present"; else ok "no c/"; fi
if [[ -d "$ROOT/rust" ]]; then bad "rust/ present"; else ok "no rust/"; fi
if find "$ROOT" -name '*.rhai' | grep -q .; then bad ".rhai present"; else ok "no rhai"; fi
if [[ -d "$ROOT/skills/poteto-mode" ]]; then bad "pstack vendored"; else ok "no pstack copy"; fi

if grep -R -n 'sitemap.xml generator\|unbounded viewport' "$ROOT/skills" >/dev/null 2>&1; then
  ok "docs mention non-goals in prose or skip"
fi

echo "$skill" | grep -qi 'pixel' && ok "skill distinguishes pixels" || bad "skill missing pixel distinction"

cmd="$(cat "$ROOT/commands/layout-content-view.md")"
echo "$cmd" | grep -q '\*\*findings\*\*' && ok "command emit findings" || bad "command missing findings row"

if ! command -v node >/dev/null 2>&1; then
  bad "node missing"
else
  if node "$ROOT/scripts/lcv.mjs" --selftest >/tmp/lcv-selftest.json; then
    ok "lcv --selftest"
  else
    bad "lcv --selftest"
  fi
  if node --test "$ROOT/test/test-predicates.mjs"; then
    ok "predicate tests"
  else
    bad "predicate tests"
  fi
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
