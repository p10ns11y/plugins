#!/usr/bin/env node
export const VIEWPORTS = Object.freeze([
  Object.freeze({ id: "phone-short", w: 375, h: 667 }),
  Object.freeze({ id: "phone", w: 375, h: 812 }),
  Object.freeze({ id: "tablet", w: 768, h: 1024 }),
  Object.freeze({ id: "desktop", w: 1280, h: 720 }),
]);

export const ROLES = Object.freeze(["must-show", "preview", "live", "interact"]);

export const LAYERS = Object.freeze([
  "route",
  "viewport",
  "orientation",
  "layout",
  "container",
  "element",
  "interactive",
]);

export function indexTree({
  route,
  viewport,
  orientation,
  layouts = [],
  containers = [],
  elements = [],
  interactives = [],
}) {
  const nodes = [];
  const routeId = route.id ?? "route";
  nodes.push({ id: routeId, layer: "route", parent: null, path: route.path });
  const viewportId = viewport.id ?? "viewport";
  nodes.push({
    id: viewportId,
    layer: "viewport",
    parent: viewport.parent ?? routeId,
    w: viewport.w,
    h: viewport.h,
  });
  const orientationId = orientation.id ?? "orientation";
  nodes.push({
    id: orientationId,
    layer: "orientation",
    parent: orientation.parent ?? viewportId,
    orientation: orientation.orientation,
    uiState: orientation.uiState ?? "",
  });
  for (const layout of layouts) {
    nodes.push({
      id: layout.id,
      layer: "layout",
      parent: layout.parent ?? orientationId,
      kind: layout.kind ?? "block",
    });
  }
  for (const container of containers) {
    nodes.push({
      id: container.id,
      layer: "container",
      parent: container.parent ?? orientationId,
      kind: container.kind ?? "flow",
    });
  }
  for (const element of elements) {
    nodes.push({
      id: element.id,
      layer: "element",
      parent: element.parent ?? orientationId,
      kind: element.kind ?? element.role ?? "must-show",
      sample: element,
    });
  }
  for (const interactive of interactives) {
    nodes.push({
      id: interactive.id ?? `${interactive.event}:${interactive.from}`,
      layer: "interactive",
      parent: interactive.parent ?? orientationId,
      kind: interactive.event ?? "event",
      event: interactive.event,
      from: interactive.from,
      success: interactive.success,
      fail: interactive.fail,
      interrupted: interactive.interrupted,
      linked: interactive.linked,
    });
  }
  return { nodes };
}

export function verifyTree(tree) {
  const byId = new Map((tree.nodes ?? []).map((node) => [node.id, node]));
  const findings = [];
  for (const node of tree.nodes ?? []) {
    if (!LAYERS.includes(node.layer)) {
      findings.push({
        id: node.id,
        kind: "tree-layer",
        fail: true,
        recipe: recipe("tree-layer"),
      });
      continue;
    }
    if (node.layer !== "route" && !byId.has(node.parent)) {
      findings.push({
        id: node.id,
        kind: "tree-orphan",
        fail: true,
        recipe: recipe("tree-orphan"),
      });
    }
    if (node.layer === "element" && node.sample) {
      const kind = classify(node.sample);
      findings.push({
        id: node.id,
        kind,
        fail: kind !== "ok" && kind !== "inner-overflow-preview",
        recipe: recipe(kind),
      });
    }
    if (node.layer === "interactive") {
      const linked = node.linked ?? Boolean(node.event && (node.success || node.from));
      const kind = linked ? "ok" : "interact-unlinked";
      findings.push({
        id: node.id,
        kind,
        fail: kind !== "ok",
        recipe: recipe(kind),
      });
    }
  }
  return findings;
}

export function layoutModeFromSize(w, h) {
  return {
    w,
    h,
    orientation: h >= w ? "portrait" : "landscape",
  };
}

export function parseInteractAttrs(attrs = {}) {
  const event = attrs["data-lcv-event"];
  if (!event) return null;
  return {
    event,
    from: attrs["data-lcv-from"] || "",
    success: attrs["data-lcv-to-success"] || "",
    fail: attrs["data-lcv-to-fail"] || "",
    interrupted: attrs["data-lcv-to-interrupted"] || "",
    machine: attrs["data-lcv-machine"] || "",
  };
}

export function staticMachine(edges) {
  const states = new Set();
  for (const edge of edges) {
    if (edge.from) states.add(edge.from);
    if (edge.success) states.add(edge.success);
    if (edge.fail) states.add(edge.fail);
    if (edge.interrupted) states.add(edge.interrupted);
  }
  return { states: [...states].sort(), edges };
}

const EPS = 1;

export function overflow(box) {
  return {
    x: box.scrollW > box.clientW + EPS,
    y: box.scrollH > box.clientH + EPS,
  };
}

function axisOverflow(value) {
  return value ?? "";
}

export function clipsContent(computed = {}) {
  const ox = axisOverflow(computed.overflowX || computed.overflow);
  const oy = axisOverflow(computed.overflowY || computed.overflow);
  return {
    x: ox === "hidden" || ox === "clip",
    y: oy === "hidden" || oy === "clip",
  };
}

export function isFitImpossible(sample) {
  if (sample.fit !== "beat") return false;
  const remH = Number(sample.remaining?.h);
  const minH = Number(sample.contentMin?.h);
  const remW = Number(sample.remaining?.w);
  const minW = Number(sample.contentMin?.w);
  const tall = Number.isFinite(remH) && Number.isFinite(minH) && minH > remH + EPS;
  const wide = Number.isFinite(remW) && Number.isFinite(minW) && minW > remW + EPS;
  return tall || wide;
}

export function isClippedMustShow(sample) {
  const mustShow = (sample.role ?? "must-show") === "must-show";
  if (!mustShow) return false;
  if (ellipseMustShow({ mustShow, computed: sample.computed ?? {} })) return true;
  if (sample.ancestorClip) return true;
  const innerOx = overflow(sample.inner);
  const clips = clipsContent(sample.computed ?? {});
  return (innerOx.x && clips.x) || (innerOx.y && clips.y);
}

export function viewDelta(before, after) {
  return {
    w: Math.abs(after.w - before.w),
    h: Math.abs(after.h - before.h),
  };
}

/** View rect unchanged while must-show text is clipped. Scrollports are reachable, not a fail. */
export function innerClipStableView(sample) {
  const d = viewDelta(sample.viewBefore, sample.viewAfter);
  return d.w < EPS && d.h < EPS && isClippedMustShow(sample);
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
  if (role === "interact") {
    return sample.linked ? "ok" : "interact-unlinked";
  }
  const docOx = overflow(sample.document);
  const innerOx = overflow(sample.inner);
  const mustShow = role === "must-show";
  const clipped = isClippedMustShow(sample);
  const stableInnerClip =
    sample.viewBefore && sample.viewAfter && innerClipStableView(sample);

  if (!crawlable(sample.landmarks ?? [])) return "landmark-missing";
  if (docOx.x) return "document-overflow-x";
  if (mustShow && isFitImpossible(sample)) return "fit-impossible";
  if (mustShow && clipped && stableInnerClip) return "inner-clip-must-show";
  if (mustShow && ellipseMustShow({ mustShow, computed: sample.computed ?? {} })) {
    return "ellipse-must-show";
  }
  if (mustShow && clipped) return "inner-clip-must-show";
  if (role === "preview" && (innerOx.x || innerOx.y)) return "inner-overflow-preview";
  if (sample.occluded) return "z-index-occlusion";
  if (sample.scrollTrap) return "scroll-trap";
  return "ok";
}

export const RECIPES = Object.freeze({
  "document-overflow-x":
    "Find the descendant whose scrollWidth exceeds the viewport. Prefer wrap (overflow-wrap) over 100vw + padding. Do not set overflow:hidden on html/body to hide it.",
  "inner-clip-must-show":
    "Must-show data was clipped (overflow hidden/clip, ellipsis, or an ancestor clip with no scrollport). Wrap or grow the box, or give the region overflow:auto so the text is reachable. Do not hide required copy.",
  "ellipse-must-show":
    "Mark the node data-lcv=preview if truncation is product-intent. Else drop -webkit-line-clamp and text-overflow:ellipsis.",
  "inner-overflow-preview":
    "Allowed. Keep data-lcv=preview. Do not treat as a fail.",
  "landmark-missing":
    "Ensure a main, a heading (h1–h3), and either navigation or a skip link so agents can index the view.",
  "tree-orphan": "Every non-route node needs a parent id in the same tree.",
  "tree-layer":
    "Layer must be route, viewport, orientation, layout, container, element, or interactive.",
  "z-index-occlusion":
    "Dump stacking contexts (position/transform/opacity/filter create them). Lower overlays or raise the occluded must-show node; never raise z-index without a named context.",
  "scroll-trap":
    "overflow:hidden on an ancestor that is not a labeled preview/dialog. Restore overflow:auto on the scrolling region; keep body lock only while a modal is open.",
  "interact-unlinked":
    "Interactive control has no data-lcv-event (and no href). Add from/success/fail/interrupted so the state machine is static.",
  "fit-impossible":
    "Must-show min-content is larger than the remaining box after chrome. Overflow cannot be CSS-patched. Rework the copy, redesign spacing/chrome, or split into another slide, dialog, or route.",
  ok: "No layout-content-view fail on this sample.",
});

export const SUGGEST = Object.freeze({
  "fit-impossible": Object.freeze([
    "rework-content: shorten or move copy that is not must-show",
    "redesign-constraints: change type, spacing, or chrome so the remaining box grows",
    "split-view: new slide, dialog, or route for the overflow beat",
  ]),
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
      layoutMode: sample.layoutMode ?? null,
      uiState: sample.uiState ?? "",
      kind,
      fail: kind !== "ok" && kind !== "inner-overflow-preview",
      recipe: recipe(kind),
      suggest: SUGGEST[kind] ?? [],
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
