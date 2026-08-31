# Predicates

Executable SoT: `scripts/lcv.mjs`. This file is the agent table.

## Boxes

```text
Box = { scrollW, scrollH, clientW, clientH }
overflow(b)  ≔ scrollW > clientW+1  ∨  scrollH > clientH+1
clips(s)     ≔ overflow axis is hidden or clip (not auto/scroll)
viewDelta    ≔ |w1-w0|, |h1-h0| on the view root rect
clipped      ≔ ellipse/line-clamp ∨ ancestorClip ∨ (overflow ∧ clips)
```

## Classify (first match)

| kind | When |
|------|------|
| `landmark-missing` | no `main`, or no heading, or neither navigation nor skip |
| `document-overflow-x` | document `scrollW > clientW+1` |
| `inner-clip-must-show` | role=must-show and clipped (hidden/clip, ellipsis, or ancestor clip with no scrollport). `overflow:auto` is reachable and not this kind |
| `ellipse-must-show` | role=must-show and (`-webkit-line-clamp`>0 or `text-overflow:ellipsis` with overflow hidden) |
| `inner-overflow-preview` | role=preview and inner overflow — **not a fail** |
| `z-index-occlusion` | sample.occluded |
| `scroll-trap` | sample.scrollTrap |
| `interact-unlinked` | role=interact and no `data-lcv-event` and no `href` |
| `fit-impossible` | `data-lcv-fit=beat` and min-content > remaining slot. CSS cannot create space. `suggest`: rework-content, redesign-constraints, split-view |
| `ok` | else |

Long document `overflow-y` is not a fail (A2).

## Roles

| `data-lcv` | Meaning |
|------------|---------|
| `must-show` | Data/copy the visitor or agent must be able to read. No ellipse. |
| `preview` | Truncation is product-intent (card blurb, chip). |
| `live` | Time-varying paint; compose with `data-visual-live`. Still must not overflow-x the document. |

Default if unmarked: treat `h1` and `[role=main]` headings as must-show; `line-clamp*` utilities as preview until proven otherwise.

## Recipes

Imported from `RECIPES` in `scripts/lcv.mjs`. Apply one kind per shot.

## Stress

1. Snapshot view root `{w,h}` and inner `{scrollW,clientW}`.
2. Set inner text to a 400-char `W` (or real long data).
3. Re-measure. `innerClipStableView` true → fail for must-show.
