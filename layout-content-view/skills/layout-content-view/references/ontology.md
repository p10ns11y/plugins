# Ontology

Verify a **compact tree** (parent ids), not a live DOM dump.

```text
Routes → Viewports → Orientation → Layouts → Containers → Elements → Interactives
```

`Page` was too coarse. A route is not a viewport. A viewport is not an orientation. Split them.

```text
Layer ∈ { route, viewport, orientation, layout, container, element, interactive }
Node  = { id, layer, parent, kind?, … }
Tree  = { nodes: Node[] }
```

| Layer | Is | Kind / payload | Verify |
|-------|----|----------------|--------|
| **route** | Feature-map path | `/profile` | one path, no second `SURFACES[]` |
| **viewport** | Named size | phone-short 375×667, phone 375×812, tablet, desktop | A5 named set only. Short height is a different viewport than tall phone. |
| **orientation** | portrait \| landscape plus **ui-state** | `slide:arrive` | walk named `data-lcv-states` |
| **layout** | Formatting context | `block` `flex` `grid` `deck` | children wrap or grow |
| **container** | Containing block | `flow` `scrollport` `clip-cage` `out-of-flow` | clip-cage fails must-show; scrollport is reachable |
| **element** | Visible content | `must-show` `preview` `live` | clip / ellipse predicates |
| **interactive** | Control plus **effects** | event, from, success, fail, interrupted | static machine. Click is optional |

## Lessons (devprofile pilot)

- Sample is route × viewport × orientation × ui-state.
- Later deck slides use `h2`. Crawlable uses `h1–h3`.
- Prefer `data-lcv-states` on the machine that owns those states. Header `menu:closed` is not the deck catalog.
- `page.evaluate` serializes only `collectInPage`. Helpers stay inside that function.
- `overflow:auto` is a scrollport only if the must-show box can scroll into view. `justify-content: center` plus `height: 100%` plus overflow auto clips the **start** and `scrollTop` stays 0. That is still a clip-cage.
- Probe the top of a must-show box (and chrome `header` bottom), not only the center. Fixed header overlap is occlusion.
- `overflow:hidden` with no scrollport between is a clip-cage.
- Interact edges in HTML are the machine.

Executable SoT: `indexTree` / `verifyTree` in `scripts/lcv.mjs`.
