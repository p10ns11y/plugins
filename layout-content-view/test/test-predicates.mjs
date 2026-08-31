import assert from "node:assert/strict";
import { test } from "node:test";
import { layoutFromSegments } from "../scripts/adapters/text-layout.mjs";
import {
  VIEWPORTS,
  classify,
  crawlable,
  ellipseMustShow,
  innerClipStableView,
  indexTree,
  isFitImpossible,
  layoutModeFromSize,
  overflow,
  parseInteractAttrs,
  recipe,
  report,
  staticMachine,
  verifyTree,
} from "../scripts/lcv.mjs";

const landmarks = [{ role: "main" }, { role: "heading" }, { role: "navigation" }];

test("named viewports are finite", () => {
  assert.equal(VIEWPORTS.length, 4);
  assert.deepEqual(
    VIEWPORTS.map((v) => v.id),
    ["phone-short", "phone", "tablet", "desktop"]
  );
  assert.equal(VIEWPORTS[0].h, 667);
});

test("document overflow-x beats inner clip", () => {
  const kind = classify({
    role: "must-show",
    document: { scrollW: 1400, clientW: 1280, scrollH: 720, clientH: 720 },
    inner: { scrollW: 100, clientW: 100, scrollH: 20, clientH: 20 },
    landmarks,
  });
  assert.equal(kind, "document-overflow-x");
});

test("causal profile-deck class: inner clip, stable view", () => {
  const view = { w: 768, h: 800 };
  const kind = classify({
    role: "must-show",
    document: { scrollW: 768, clientW: 768, scrollH: 800, clientH: 800 },
    inner: { scrollW: 4476, clientW: 200, scrollH: 24, clientH: 24 },
    viewBefore: view,
    viewAfter: view,
    computed: { textOverflow: "ellipsis", overflow: "hidden", lineClamp: 1 },
    landmarks,
  });
  assert.equal(kind, "inner-clip-must-show");
  assert.match(recipe(kind), /Must-show/);
});

test("preview inner overflow is not a fail", () => {
  const findings = report([
    {
      id: "card",
      role: "preview",
      document: { scrollW: 375, clientW: 375, scrollH: 2000, clientH: 812 },
      inner: { scrollW: 900, clientW: 300, scrollH: 48, clientH: 48 },
      computed: { lineClamp: 3, overflow: "hidden", textOverflow: "ellipsis" },
      landmarks,
    },
  ]);
  assert.equal(findings[0].kind, "inner-overflow-preview");
  assert.equal(findings[0].fail, false);
});

test("ellipse on must-show without inner overflow", () => {
  const kind = classify({
    role: "must-show",
    document: { scrollW: 1280, clientW: 1280, scrollH: 720, clientH: 720 },
    inner: { scrollW: 200, clientW: 200, scrollH: 20, clientH: 20 },
    computed: { lineClamp: 2, overflow: "hidden", textOverflow: "ellipsis" },
    landmarks,
  });
  assert.equal(kind, "ellipse-must-show");
});

test("missing landmarks", () => {
  assert.equal(crawlable([]), false);
  const kind = classify({
    role: "must-show",
    document: { scrollW: 375, clientW: 375, scrollH: 800, clientH: 800 },
    inner: { scrollW: 100, clientW: 100, scrollH: 20, clientH: 20 },
    landmarks: [],
  });
  assert.equal(kind, "landmark-missing");
});

test("overflow helper", () => {
  assert.equal(overflow({ scrollW: 10, clientW: 10, scrollH: 10, clientH: 10 }).x, false);
  assert.equal(overflow({ scrollW: 12, clientW: 10, scrollH: 10, clientH: 10 }).x, true);
});

test("innerClipStableView requires unchanged view and a clip policy", () => {
  const clipped = {
    role: "must-show",
    inner: { scrollW: 500, clientW: 100, scrollH: 20, clientH: 20 },
    computed: { overflow: "hidden" },
  };
  assert.equal(
    innerClipStableView({
      ...clipped,
      viewBefore: { w: 768, h: 800 },
      viewAfter: { w: 768, h: 800 },
    }),
    true
  );
  assert.equal(
    innerClipStableView({
      ...clipped,
      viewBefore: { w: 768, h: 800 },
      viewAfter: { w: 768, h: 1200 },
    }),
    false
  );
});

test("scrollport overflow is not a must-show fail", () => {
  const kind = classify({
    role: "must-show",
    document: { scrollW: 768, clientW: 768, scrollH: 800, clientH: 800 },
    inner: { scrollW: 200, clientW: 200, scrollH: 1200, clientH: 400 },
    computed: { overflow: "auto", overflowY: "auto", textOverflow: "clip" },
    landmarks,
  });
  assert.equal(kind, "ok");
});

test("scrollport that cannot reveal the start is still clip", () => {
  const kind = classify({
    role: "must-show",
    document: { scrollW: 375, clientW: 375, scrollH: 667, clientH: 667 },
    inner: { scrollW: 200, clientW: 200, scrollH: 40, clientH: 40 },
    computed: { overflowY: "auto", overflow: "auto" },
    ancestorClip: true,
    landmarks,
  });
  assert.equal(kind, "inner-clip-must-show");
});

test("ancestor clip without a scrollport fails", () => {
  const kind = classify({
    role: "must-show",
    document: { scrollW: 375, clientW: 375, scrollH: 812, clientH: 812 },
    inner: { scrollW: 200, clientW: 200, scrollH: 40, clientH: 40 },
    computed: { overflow: "visible" },
    ancestorClip: true,
    landmarks,
  });
  assert.equal(kind, "inner-clip-must-show");
});

test("ellipseMustShow ignores preview", () => {
  assert.equal(
    ellipseMustShow({
      mustShow: false,
      computed: { lineClamp: 3, textOverflow: "ellipsis", overflow: "hidden" },
    }),
    false
  );
});

test("layout-mode uses orientation from size", () => {
  assert.equal(layoutModeFromSize(375, 812).orientation, "portrait");
  assert.equal(layoutModeFromSize(1280, 720).orientation, "landscape");
});

test("static machine reads success fail interrupted", () => {
  const edge = parseInteractAttrs({
    "data-lcv-event": "next",
    "data-lcv-from": "slide:arrive",
    "data-lcv-to-success": "slide:inch-at-a-time",
    "data-lcv-to-fail": "slide:arrive",
    "data-lcv-to-interrupted": "slide:arrive",
  });
  const machine = staticMachine([edge]);
  assert.deepEqual(machine.states, ["slide:arrive", "slide:inch-at-a-time"]);
});

test("unlinked interact fails", () => {
  assert.equal(classify({ role: "interact", linked: false }), "interact-unlinked");
  assert.equal(classify({ role: "interact", linked: true }), "ok");
});

test("seven-layer tree verifies parent ids and interact effects", () => {
  const tree = indexTree({
    route: { id: "route", path: "/profile" },
    viewport: { id: "phone", w: 375, h: 812 },
    orientation: { id: "portrait", orientation: "portrait", uiState: "slide:arrive" },
    layouts: [{ id: "deck", kind: "deck" }],
    containers: [{ id: "pane", parent: "deck", kind: "scrollport" }],
    elements: [
      {
        id: "title",
        parent: "pane",
        role: "must-show",
        document: { scrollW: 375, clientW: 375, scrollH: 812, clientH: 812 },
        inner: { scrollW: 200, clientW: 200, scrollH: 40, clientH: 40 },
        computed: { overflow: "visible" },
        landmarks,
      },
    ],
    interactives: [
      {
        id: "next",
        parent: "portrait",
        event: "next",
        from: "slide:arrive",
        success: "slide:inch-at-a-time",
        fail: "slide:arrive",
        interrupted: "slide:arrive",
        linked: true,
      },
    ],
  });
  const out = verifyTree(tree);
  assert.equal(tree.nodes.map((n) => n.layer).join(">"), "route>viewport>orientation>layout>container>element>interactive");
  assert.equal(
    out.filter((row) => row.fail).length,
    0
  );
});

test("orphan node fails tree verify", () => {
  const out = verifyTree({
    nodes: [{ id: "ghost", layer: "element", parent: "missing" }],
  });
  assert.equal(out[0].kind, "tree-orphan");
});

test("fit-impossible when min-content exceeds the remaining beat", () => {
  const sample = {
    role: "must-show",
    fit: "beat",
    remaining: { w: 375, h: 400 },
    contentMin: { w: 375, h: 900 },
    document: { scrollW: 375, clientW: 375, scrollH: 667, clientH: 667 },
    inner: { scrollW: 375, clientW: 375, scrollH: 900, clientH: 400 },
    landmarks,
  };
  assert.equal(isFitImpossible(sample), true);
  assert.equal(classify(sample), "fit-impossible");
  const row = report([sample])[0];
  assert.equal(row.suggest.length, 3);
  assert.match(row.suggest[2], /split-view/);
});

test("font-engine wrap is arithmetic on cached widths", () => {
  const two = layoutFromSegments([{ w: 80 }, { w: 10 }, { w: 80 }], 100, 20);
  assert.equal(two.lineCount, 2);
  assert.equal(two.height, 40);
  const one = layoutFromSegments([{ w: 40 }, { w: 10 }, { w: 40 }], 100, 20);
  assert.equal(one.lineCount, 1);
  assert.equal(one.height, 20);
});

test("beat that fits is not fit-impossible", () => {
  assert.equal(
    isFitImpossible({
      fit: "beat",
      remaining: { w: 375, h: 800 },
      contentMin: { w: 360, h: 400 },
    }),
    false
  );
});
