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

> **Load rule:** This file owns **when + steps**. Predicates: [references/predicates.md](references/predicates.md) (executable SoT: `scripts/lcv.mjs`). Graph schema: [references/sitemap-graph.md](references/sitemap-graph.md). Drive recipe: [references/harness.md](references/harness.md). Pilot: [references/pilot-devprofile.md](references/pilot-devprofile.md). Do not paste pstack visual-parity. Do not add a second route catalog when a verify feature map exists.

```text
// Signature
LCV        : this skill
View       : named viewport × one path
Graph      : landmarks + index edges (not XML sitemap.xml)
Role       ∈ { must-show, preview, live }
Fail       : must-show clipped | document overflow-x | missing landmarks | occlusion | scroll-trap
OK-info    : preview inner overflow
Not LCV    : PNG pixel-diff (compose with verify-* if the repo has it)

// Axioms
A1  Stability ≔ graph reachable ∧ must-show unclipped — not paint match
A2  Document overflow-x is a fail; long-page overflow-y is not
A3  Inner overflow + unchanged view box = clip policy, not a missing layout solver
A4  Ellipse/line-clamp on must-show fails; on preview is allowed
A5  Named viewports only (default phone/tablet/desktop) — no unbounded matrix
A6  Reuse the project's verify feature map paths; never a second SURFACES[]
```

## When to use

Overflow, clip, z-index, scroll traps, “looks messy at this width”, agent-crawlable IA, or a redesign that should **not** invalidate the stability contract.

Skip: pixel-exact migration (pstack **visual-parity** + existing snapshots). Phrase-level copy tests. Native/mobile shells (v1 is web).

## Steps

1. **Graph.** Load verify `features/*.md` `path:` if present; else list app routes. Walk landmarks (`main`, one `h1`, `navigation` or skip link). Optional product marks: `data-lcv="must-show|preview|live"` (compose with `data-visual-live` for paint that must be masked, not clipped).
2. **Viewports.** Default set in `scripts/lcv.mjs` `VIEWPORTS`. Do not invent extra widths unless the human named them.
3. **Measure.** Per path × viewport, collect boxes (`client*` / `scroll*`) for document, view root, and each marked region. Run `classify` / `report` from `scripts/lcv.mjs` (or the same predicates in Playwright `page.evaluate`).
4. **Stress (must-show only).** Inject a long string into one must-show node. If the **view rect stays put** and the inner `scrollWidth` grows → `inner-clip-must-show`. If the page grows/wraps and the text remains readable → pass.
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
