---
name: lcv-implement
description: >-
  Companion to layout-content-view for code implementers. Propose then write
  data-lcv marks on routes and components so the probe can classify must-show,
  preview, beats, and interact edges. Use when /lcv-implement, adding a page,
  wiring a deck/dialog/nav, or the probe reports interact-unlinked / no beat.
---

# lcv-implement

> **Load rule:** This file owns **the implementer process**. Attribute names: [../layout-content-view/references/interact.md](../layout-content-view/references/interact.md). Roles: [../layout-content-view/references/predicates.md](../layout-content-view/references/predicates.md). Tree: [../layout-content-view/references/ontology.md](../layout-content-view/references/ontology.md). Probe: skill **layout-content-view**. Do not auto-stamp the whole app.

```text
// Signature
Impl     : this skill
Probe    : layout-content-view
Mark     ∈ { must-show, preview, live, beat, event }
Write    : only rows the implementer accepts from the propose table
```

## When to use

New route, new dialog, new pager, or `/lcv-implement`. After a probe that is blind (`interact-unlinked`, no `fit-impossible` on a theater, missing must-show).

Skip: probe-only on an already marked surface. Pixel snapshots.

## Heuristics (propose, do not assume)

| Signal in code or DOM | Propose |
|-----------------------|---------|
| `h1`, dialog title, hiring/lead copy | `data-lcv=must-show` |
| `line-clamp`, `text-overflow:ellipsis` on a card/chip | `data-lcv=preview` |
| `data-visual-live` | `data-lcv=live` |
| Viewport theater (one beat, definite height) | `data-lcv-slot=beat` on the slot, `data-lcv-fit=beat` on the pane |
| `<a href>` | `data-lcv-event=navigate` `to-success=href` `to-fail=from` `to-interrupted=from` |
| `<button>` that changes view | `event` + from/success/fail/interrupted. Disabled stay = fail=from |
| Region with named views | `data-lcv-machine` `data-lcv-ui-state` `data-lcv-states` |

Ambiguous copy stays unmarked until the human names must-show vs preview.

## Steps

1. **Inventory.** Routes from the verify feature map `path:` if present; else app router files. No second `SURFACES[]`.
2. **Propose.** Run `scripts/propose-marks.mjs` on the app `cwd` (or grep the same signals). Emit the table below. Do not write files in this step.
3. **Accept.** Implementer keeps, drops, or edits rows. Guessed `must-show` vs `preview` is the dangerous column.
4. **Write.** Smallest JSX/HTML change. Optional helper: spread object with the five interact attrs (same shape as `lcvInteract` in the pilot). Do not inject a runtime wrapper around every control.
5. **Probe.** Skill **layout-content-view** on the marked routes. One recipe per fail. `fit-impossible` may suggest adaptive-type only above 14px / 0.875.

## Emit

```markdown
## LCV-implement
| sel / file | mark | from | success | fail | interrupted | accept |
|------------|------|------|---------|------|-------------|--------|
```

## Done when

- [ ] Propose table exists before the first write
- [ ] Accepted marks are in the DOM (`data-lcv` / event / beat)
- [ ] Probe run on those routes
- [ ] Unaccepted rows were not written

## Do not

- Silent rewrite of the repo
- Mark every `button` `must-show`
- Treat `href` as failure/interrupt (those stay current view)
- Copy the interact attribute list into this file
- Add a second route catalog
