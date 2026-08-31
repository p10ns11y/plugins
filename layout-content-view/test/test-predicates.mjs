import assert from "node:assert/strict";
import { test } from "node:test";
import {
  VIEWPORTS,
  classify,
  crawlable,
  ellipseMustShow,
  innerClipStableView,
  overflow,
  recipe,
  report,
} from "../scripts/lcv.mjs";

const landmarks = [{ role: "main" }, { role: "heading" }, { role: "navigation" }];

test("named viewports are finite", () => {
  assert.equal(VIEWPORTS.length, 3);
  assert.deepEqual(
    VIEWPORTS.map((v) => v.id),
    ["phone", "tablet", "desktop"]
  );
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

test("innerClipStableView requires unchanged view", () => {
  assert.equal(
    innerClipStableView({
      viewBefore: { w: 768, h: 800 },
      viewAfter: { w: 768, h: 800 },
      inner: { scrollW: 500, clientW: 100, scrollH: 20, clientH: 20 },
    }),
    true
  );
  assert.equal(
    innerClipStableView({
      viewBefore: { w: 768, h: 800 },
      viewAfter: { w: 768, h: 1200 },
      inner: { scrollW: 500, clientW: 100, scrollH: 20, clientH: 20 },
    }),
    false
  );
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
