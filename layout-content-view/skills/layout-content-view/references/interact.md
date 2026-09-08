# Interact edges

The **interactive** layer of [ontology.md](ontology.md). Effects: success, fail, interrupted. Static. Agents read HTML attributes. They do not have to click first.

```text
data-lcv-machine     named machine on a region
data-lcv-ui-state    current view (slide:cue, menu:open, …)
data-lcv-states      space-separated views this machine can occupy
data-lcv-event       the event this control fires
data-lcv-from        view before the event
data-lcv-to-success  view if the event succeeds
data-lcv-to-fail     view if it fails (disabled, reject, stay)
data-lcv-to-interrupted  view if the visitor abandons
```

CSS mirrors the same facts as custom properties on `[data-lcv-event]`. `html[data-lcv-debug]` paints `event → success` after the control.

`scripts/lcv.mjs` `parseInteractAttrs` + `staticMachine` + `planVisits` evaluate the graph without a browser. The web adapter only collects the attributes. `LCV_WALK_STATES=0` skips visiting named catalog states (URL `slide:*` and event-driven `to-success`).
