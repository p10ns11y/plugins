---
name: layout-content-view
description: >-
  Audit web layout-content-view stability: landmark/sitemap graph, named
  viewports, overflow/clip/ellipsis on must-show data, z-index and scroll
  quirks. Survives redesigns because it measures boxes and roles, not pixels.
  Use when /layout-content-view, visual coherence, overflow, clip, ellipse
  cut, sitemap graph, agent-crawlable layout, or viewport distortion.
---

# layout-content-view

> **Load rule:** This file owns **when + steps**. Ontology: [references/ontology.md](references/ontology.md). Predicates: [references/predicates.md](references/predicates.md) (executable SoT: `scripts/lcv.mjs`). Index graph: [references/sitemap-graph.md](references/sitemap-graph.md). Interact: [references/interact.md](references/interact.md). Drive: [references/harness.md](references/harness.md). Pilot: [references/pilot-devprofile.md](references/pilot-devprofile.md). Do not paste pstack visual-parity. Do not add a second route catalog when a verify feature map exists.

```text
// Signature
LCV        : this skill — strategy only
Tree       : Routes → Viewports → Orientation → Layouts → Containers → Elements → Interactives
View       : named viewport × orientation × ui-state × one route
Graph      : landmarks + flow + interact edges (not XML sitemap.xml)
Role       ∈ { must-show, preview, live, interact }
Fail       : must-show clipped | document overflow-x | missing landmarks | occlusion | scroll-trap | interact-unlinked
OK-info    : preview inner overflow
Adapter    : fills samples (web: DOM APIs hosted by Playwright/Brave/CDP; mobile later)
Not LCV    : PNG pixel-diff (compose with verify-* if the repo has it)

// Axioms
A1  Stability ≔ graph reachable ∧ must-show unclipped — not paint match
A2  Document overflow-x is a fail; long-page overflow-y is not
A3  Clip ≔ overflow hidden/clip, ellipsis, or ancestor clip with no scrollport. overflow:auto is reachable
A4  Ellipse/line-clamp on must-show fails; on preview is allowed
A5  Named viewports only (default phone/tablet/desktop) — no unbounded matrix
A6  Reuse the project's verify feature map paths; never a second SURFACES[]
A7  Strategy does not name a browser. Adapters pick DOM, Playwright, cloud browsers, or native SDKs
A8  Interactive controls declare from / success / fail / interrupted in HTML so the machine is static
A9  Verify the seven-layer tree (ontology.md). Adapters fill nodes. Strategy does not dump the live DOM
```

## When to use

Overflow, clip, z-index, scroll traps, “looks messy at this width”, agent-crawlable IA, or a redesign that should **not** invalidate the stability contract.

Skip: pixel-exact migration (pstack **visual-parity** + existing snapshots). Phrase-level copy tests. Native adapters are not shipped yet. The strategy still applies.

## Steps

1. **Graph.** Load verify `features/*.md` `path:` if present; else list app routes. Walk landmarks (`main`, one `h1`, `navigation` or skip link). Marks: `data-lcv`, `data-lcv-event` / `data-lcv-to-*` ([references/interact.md](references/interact.md)).
2. **Layout-mode.** Named viewports plus orientation from size. Walk named `data-lcv-states` (profile `slide:*`) at those viewports. Not every CSS breakpoint.
3. **Measure.** Adapter fills the tree plus boxes. Web uses DOM (`scrollWidth`, `getComputedStyle`, `elementFromPoint`). Playwright or another host only launches the page. Run `indexTree` / `verifyTree` / `classify` / `report` from `scripts/lcv.mjs`.
4. **Stress (must-show only).** Inject a long string into one must-show node. Fail if the view stays put **and** the text is clipped (hidden/clip, ellipsis, ancestor clip with no scrollport). Wrap, grow, or `overflow:auto` passes.
5. **One-shot fix.** Apply **one** recipe from the finding `kind` (predicates.md). Re-measure that path × viewport. Do not auto-delete every `line-clamp` in the repo.
6. **Compose.** UX/pixel skills stay owners of visitor drive and PNG baselines. This skill never claims visual parity.

## Done when

- [ ] Findings JSON from `report()` for each mapped path × named viewport
- [ ] Every `fail: true` has a `kind` + recipe; preview overflow is not a fail
- [ ] Must-show nodes have no ellipse/line-clamp after the in-scope fix (or were reclassified `preview` with human intent)
- [ ] Feature-map paths were not duplicated into a new catalog

## Do not

- Treat PNG snapshots as this algorithm
- Generate `sitemap.xml` as layout SoT
- Unbounded viewport × content fuzz
- Vendor pstack; inline control-graph / EVA
- Reuse print-CV clamp policy (`cv-layout-policy`) for live web
- Kill document overflow by `overflow:hidden` on `html`/`body`
