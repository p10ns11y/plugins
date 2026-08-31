#!/usr/bin/env node
export const VIEWPORTS = Object.freeze([
  Object.freeze({ id: "phone", w: 375, h: 812 }),
  Object.freeze({ id: "tablet", w: 768, h: 1024 }),
  Object.freeze({ id: "desktop", w: 1280, h: 720 }),
]);

export const ROLES = Object.freeze(["must-show", "preview", "live"]);

const EPS = 1;

export function overflow(box) {
  return {
    x: box.scrollW > box.clientW + EPS,
    y: box.scrollH > box.clientH + EPS,
  };
}

export function viewDelta(before, after) {
  return {
    w: Math.abs(after.w - before.w),
    h: Math.abs(after.h - before.h),
  };
}

/** View rect unchanged while an inner box overflows = clip policy, not a missing view-box solver. */
export function innerClipStableView({ viewBefore, viewAfter, inner }) {
  const d = viewDelta(viewBefore, viewAfter);
  const innerOx = overflow(inner);
  return d.w < EPS && d.h < EPS && (innerOx.x || innerOx.y);
}

export function ellipseMustShow({ mustShow, computed }) {
  if (!mustShow) return false;
  const lineClamp = Number(computed.lineClamp ?? computed.webkitLineClamp ?? 0);
  const clamp = Number.isFinite(lineClamp) && lineClamp > 0;
  const ellipsis = computed.textOverflow === "ellipsis";
  const hidden =
    computed.overflow === "hidden" ||
    computed.overflowX === "hidden" ||
    computed.overflowY === "hidden";
  return clamp || (ellipsis && hidden);
}

export function crawlable(landmarks) {
  const has = (role) => landmarks.some((n) => n.role === role);
  return has("main") && has("heading") && (has("navigation") || has("skip"));
}

export function classify(sample) {
  const role = sample.role ?? "must-show";
  const docOx = overflow(sample.document);
  const innerOx = overflow(sample.inner);
  const mustShow = role === "must-show";
  const clipped =
    mustShow &&
    (ellipseMustShow({ mustShow, computed: sample.computed ?? {} }) || innerOx.x || innerOx.y);
  const stableInnerClip =
    sample.viewBefore &&
    sample.viewAfter &&
    innerClipStableView({
      viewBefore: sample.viewBefore,
      viewAfter: sample.viewAfter,
      inner: sample.inner,
    });

  if (!crawlable(sample.landmarks ?? [])) return "landmark-missing";
  if (docOx.x) return "document-overflow-x";
  if (mustShow && clipped && stableInnerClip) return "inner-clip-must-show";
  if (mustShow && ellipseMustShow({ mustShow, computed: sample.computed ?? {} })) {
    return "ellipse-must-show";
  }
  if (mustShow && (innerOx.x || innerOx.y)) return "inner-clip-must-show";
  if (role === "preview" && (innerOx.x || innerOx.y)) return "inner-overflow-preview";
  if (sample.occluded) return "z-index-occlusion";
  if (sample.scrollTrap) return "scroll-trap";
  return "ok";
}

export const RECIPES = Object.freeze({
  "document-overflow-x":
    "Find the descendant whose scrollWidth exceeds the viewport. Prefer wrap (overflow-wrap) over 100vw + padding. Do not set overflow:hidden on html/body to hide it.",
  "inner-clip-must-show":
    "Must-show data was clipped while the view box stayed put. Remove line-clamp/ellipsis; overflow:visible; allow the box to grow or wrap. min-width:0 is for flex shrink, not for hiding required copy.",
  "ellipse-must-show":
    "Mark the node data-lcv=preview if truncation is product-intent. Else drop -webkit-line-clamp and text-overflow:ellipsis.",
  "inner-overflow-preview":
    "Allowed. Keep data-lcv=preview. Do not treat as a fail.",
  "landmark-missing":
    "Ensure one h1, a main, and either navigation or a skip link so agents can index the view.",
  "z-index-occlusion":
    "Dump stacking contexts (position/transform/opacity/filter create them). Lower overlays or raise the occluded must-show node; never raise z-index without a named context.",
  "scroll-trap":
    "overflow:hidden on an ancestor that is not a labeled preview/dialog. Restore overflow:auto on the scrolling region; keep body lock only while a modal is open.",
  ok: "No layout-content-view fail on this sample.",
});

export function recipe(kind) {
  return RECIPES[kind] ?? RECIPES.ok;
}

export function report(samples) {
  return samples.map((sample) => {
    const kind = classify(sample);
    return {
      id: sample.id ?? sample.sel ?? "anon",
      path: sample.path ?? "",
      viewport: sample.viewport ?? null,
      kind,
      fail: kind !== "ok" && kind !== "inner-overflow-preview",
      recipe: recipe(kind),
    };
  });
}

function selftest() {
  const view = { w: 768, h: 800 };
  const samples = [
    {
      id: "clip-label",
      role: "must-show",
      document: { scrollW: 768, clientW: 768, scrollH: 800, clientH: 800 },
      inner: { scrollW: 4476, clientW: 200, scrollH: 24, clientH: 24 },
      viewBefore: view,
      viewAfter: view,
      computed: { textOverflow: "ellipsis", overflow: "hidden", lineClamp: 1 },
      landmarks: [{ role: "main" }, { role: "heading" }, { role: "navigation" }],
    },
    {
      id: "preview-ok",
      role: "preview",
      document: { scrollW: 375, clientW: 375, scrollH: 2000, clientH: 812 },
      inner: { scrollW: 900, clientW: 300, scrollH: 48, clientH: 48 },
      computed: { textOverflow: "ellipsis", overflow: "hidden", lineClamp: 3 },
      landmarks: [{ role: "main" }, { role: "heading" }, { role: "navigation" }],
    },
  ];
  const out = report(samples);
  if (out[0].kind !== "inner-clip-must-show" || !out[0].fail) {
    throw new Error(`expected inner-clip-must-show, got ${out[0].kind}`);
  }
  if (out[1].kind !== "inner-overflow-preview" || out[1].fail) {
    throw new Error(`expected preview info, got ${out[1].kind}`);
  }
  console.log(JSON.stringify({ ok: true, findings: out }, null, 2));
}

const isMain =
  Boolean(process.argv[1]) &&
  (process.argv[1].endsWith("lcv.mjs") || process.argv[1].endsWith("/lcv.mjs"));
if (isMain && process.argv.includes("--selftest")) {
  selftest();
}
