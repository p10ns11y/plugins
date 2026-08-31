# layout-content-view

Web-first **layout × content × view** stability for agents. A view is stable when landmark/index graph stays reachable and **must-show** text is geometrically unclipped — not when pixels match a PNG.

Pixel baselines miss inner clip while the view box stays fixed. Document `scrollWidth` checks miss the same class. This plugin names that class and a one-shot recipe.

```text
  /layout-content-view     graph + geometry + content-stress → findings JSON
```

Pilot: **devprofile** (compose with `verify-devprofile` feature map; do not add a second route catalog).

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin marketplace update
grok plugin install layout-content-view --trust
```

Name install reads the marketplace catalog on the source default branch. Until that catalog lists this plugin, install the git ref and subdir:

```bash
grok plugin install p10ns11y/plugins@feat/layout-content-view#layout-content-view --trust
```

## Verify

```bash
./test/test-thin.sh
node --test test/test-predicates.mjs
```

Live probe (from the app repo, Brave + Playwright already there):

```bash
FEATURES_DIR=.cursor/skills/verify-devprofile/features \
ORIGIN=http://localhost:3000 \
node "$LCV_ROOT/scripts/probe-web.mjs"
```

`LCV_ROOT` is the installed plugin directory from `grok plugin details layout-content-view`. See [skills/layout-content-view/references/harness.md](skills/layout-content-view/references/harness.md).

## Layout

```text
plugin.json
LICENSE
README.md
commands/layout-content-view.md
cursor/commands/layout-content-view.md
agents/layout-content-view.md
scripts/lcv.mjs                 # executable SoT for predicates
skills/layout-content-view/
  SKILL.md
  references/predicates.md
  references/sitemap-graph.md
  references/harness.md
  references/pilot-devprofile.md
test/test-thin.sh
test/test-predicates.mjs
test/fixtures/ellipsis.html
```

## Non-goals (v1)

Native/mobile shells, XML sitemap generator, pixel-diff as the algorithm, C/Rust kernel, auto-deleting product `line-clamp`, unbounded viewport matrices.
