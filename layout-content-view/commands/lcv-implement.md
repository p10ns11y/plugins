---
description: Propose then write data-lcv marks so layout-content-view can probe an app.
argument-hint: optional path or glob
---

# /lcv-implement

Load skill **lcv-implement**. Attribute names stay in layout-content-view `references/interact.md`.

`$ARGUMENTS` = route or file glob. Empty = feature-map paths or app router.

1. Inventory routes. No second `SURFACES[]`.
2. Propose marks (`scripts/propose-marks.mjs` or the heuristic table). Do not write yet.
3. Write only accepted rows.
4. Probe with **layout-content-view**.
