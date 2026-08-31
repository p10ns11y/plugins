# Harness

## Offline (plugin repo)

```bash
./test/test-thin.sh
node --test test/test-predicates.mjs
node scripts/lcv.mjs --selftest
```

These prove the **algorithm**, not a live site.

## Tree

`indexTree` / `verifyTree` in `scripts/lcv.mjs` are the strategy. Spine: Routes → Viewports → Orientation → Layouts → Containers → Elements → Interactives. See [ontology.md](ontology.md).

## Adapters

`scripts/lcv.mjs` is the strategy. It never launches a browser.

| Surface | Adapter | Host (inner, pick one) |
|---------|---------|------------------------|
| Web | `scripts/adapters/web-dom.mjs` (DOM APIs) | Playwright + Brave, CDP, cloud browser. `page.evaluate` only serializes `collectInPage`, so helpers stay inside that function. |
| Native | not shipped | SDK layout bounds / simulator |

## Live web (app repo)

From the app checkout, after `grok plugin install layout-content-view --trust` (or `p10ns11y/plugins#layout-content-view`). Resolve the plugin dir from `grok plugin details layout-content-view`. Do not pass a filesystem path to `grok plugin install`.

```bash
pnpm verify:doctor
FEATURES_DIR=.cursor/skills/verify-devprofile/features \
ORIGIN=http://localhost:3000 \
node "$LCV_ROOT/scripts/probe-web.mjs"
```

`LCV_STRESS=1` injects long text into must-show nodes. `VERIFY_FEATURE=/profile` limits paths. `LCV_OUT=lcv.json` writes the report. Playwright comes from the app `cwd` (`@playwright/test`). Brave Beta is required.

Document `scrollWidth` vs `clientWidth` on `<html>` is necessary and **not sufficient** (inner clip with stable view).

## Visual tools

Screenshots are **evidence attachments**, not the pass/fail predicate. If the repo has PNG baselines, keep them under the verify skill. Magenta `data-visual-live` masks are paint, not clip.

## Z-index / scroll

In `evaluate`: walk ancestors for `overflow: hidden|clip` (scroll-trap) and stacking contexts (`position` ≠ static with z-index, `transform`/`opacity`/`filter` ≠ none). Set `sample.scrollTrap` / `sample.occluded` when a must-show node's hit rect is covered or not scrollable to.
