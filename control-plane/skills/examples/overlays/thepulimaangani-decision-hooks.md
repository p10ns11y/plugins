# Thepulimaangani — decision architect overlay

**Example provenance:** [thepulimaangani](https://github.com/p10ns11y/thepulimaangani) — Tamil prosody tools, WASM parser, metre prediction.

Load with [higher-order-decision-architect](../../higher-order-decision-architect/SKILL.md) when making material decisions in that repo.

## Domain hooks

- **Parser / WASM / metre:** Read `tamil-seiyul-alagi/METRE_PREDICTION.md` for metre stack first- and higher-order effects; bump schemas when wire contracts change.
- **Branches / PRs:** Follow project `branch-naming` rule, `AGENTS.md`, and `dx/HUMAN_SYNC.md` for human sync points.

## Typical critical zones

| Zone | Higher-order risk |
|------|-------------------|
| WASM wire format | Breaking all clients on schema drift |
| Metre hypothesis UI | Wrong defaults compound through export pipelines |
| Linkage / foot indexing | Off-by-one errors propagate across parser + display |
