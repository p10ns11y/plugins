export function collectInPage(stressMustShow) {
  const clips = (value) => value === "hidden" || value === "clip";
  const scrolls = (value) => value === "auto" || value === "scroll";
  const boxOf = (el) => {
    if (!el) return null;
    return {
      scrollW: el.scrollWidth,
      scrollH: el.scrollHeight,
      clientW: el.clientWidth,
      clientH: el.clientHeight,
      w: el.getBoundingClientRect().width,
      h: el.getBoundingClientRect().height,
    };
  };
  const computedOf = (el) => {
    const s = getComputedStyle(el);
    return {
      overflow: s.overflow,
      overflowX: s.overflowX,
      overflowY: s.overflowY,
      textOverflow: s.textOverflow,
      lineClamp: s.webkitLineClamp || s.lineClamp,
      webkitLineClamp: s.webkitLineClamp,
    };
  };
  const occluded = (el) => {
    const r = el.getBoundingClientRect();
    if (r.width < 1 || r.height < 1) return false;
    const header = document.querySelector("header");
    const chromeBottom = header ? header.getBoundingClientRect().bottom : 0;
    if (r.top < chromeBottom - 1) return true;
    const probes = [
      [r.x + r.width / 2, r.y + Math.min(4, r.height / 4)],
      [r.x + r.width / 2, r.y + r.height / 2],
    ];
    return probes.some(([x, y]) => {
      const hit = document.elementFromPoint(x, y);
      return Boolean(hit && hit !== el && !el.contains(hit) && !hit.contains(el));
    });
  };
  const ancestorClip = (el) => {
    const r = el.getBoundingClientRect();
    let node = el.parentElement;
    while (node && node !== document.documentElement) {
      const s = getComputedStyle(node);
      const pr = node.getBoundingClientRect();
      if (scrolls(s.overflowY)) {
        if (r.top < pr.top - 1 && node.scrollTop <= 1) return true;
        if (r.bottom > pr.bottom + 1 && node.scrollHeight <= node.clientHeight + 1) {
          return true;
        }
      } else if (clips(s.overflowY) && (r.top < pr.top - 1 || r.bottom > pr.bottom + 1)) {
        return true;
      }
      if (clips(s.overflowX) && (r.left < pr.left - 1 || r.right > pr.right + 1)) {
        const canScrollX = scrolls(s.overflowX) && node.scrollWidth > node.clientWidth + 1;
        if (!canScrollX) return true;
      }
      node = node.parentElement;
    }
    return false;
  };
  const landmarks = [];
  if (document.querySelector("main")) landmarks.push({ role: "main" });
  if (document.querySelector("h1, h2, h3")) landmarks.push({ role: "heading" });
  if (document.querySelector("nav")) landmarks.push({ role: "navigation" });
  if (document.querySelector('a[href="#main"], a[href="#content"]')) {
    landmarks.push({ role: "skip" });
  }

  const seen = new Set();
  const nodes = [];
  const pushNode = (id, sel, el, role) => {
    if (!el || seen.has(el)) return;
    seen.add(el);
    if (stressMustShow && role === "must-show") {
      el.textContent = `${"W".repeat(400)} ${el.textContent || ""}`;
    }
    nodes.push({
      id,
      sel,
      role,
      inner: boxOf(el),
      computed: computedOf(el),
      occluded: role === "must-show" ? occluded(el) : false,
      ancestorClip: role === "must-show" ? ancestorClip(el) : false,
    });
  };

  const dialog = document.querySelector("dialog[open], [role='dialog']:not([aria-hidden='true'])");
  const dialogTitle = dialog?.querySelector("h1, h2, [id$='title']");
  if (dialogTitle) {
    pushNode("dialog-title", "dialog heading", dialogTitle, "must-show");
  } else {
    pushNode("h1", "h1", document.querySelector("h1"), "must-show");
  }
  for (const el of document.querySelectorAll("[data-lcv]")) {
    const role = el.getAttribute("data-lcv") || "must-show";
    pushNode(el.id || `data-lcv-${nodes.length}`, "[data-lcv]", el, role);
  }
  for (const el of document.querySelectorAll('[class*="line-clamp"]')) {
    pushNode(el.id || `line-clamp-${nodes.length}`, '[class*="line-clamp"]', el, "preview");
  }

  const listed = [...document.querySelectorAll("[data-lcv-states]")]
    .flatMap((node) => (node.getAttribute("data-lcv-states") || "").split(/\s+/))
    .map((s) => s.trim())
    .filter(Boolean);
  const machineNodes = [...document.querySelectorAll("[data-lcv-machine]")].map((el) => ({
    name: el.getAttribute("data-lcv-machine") || "",
    uiState: el.getAttribute("data-lcv-ui-state") || "",
    states: (el.getAttribute("data-lcv-states") || "").split(/\s+/).map((s) => s.trim()).filter(Boolean),
  }));
  const catalog = [...machineNodes].reverse().find((item) => item.states.length > 0);
  const uiState = catalog?.uiState || machineNodes[0]?.uiState || "";
  const interact = [];
  const seenInteract = new Set();
  const readEdge = (el) => {
    const event = el.getAttribute("data-lcv-event") || "";
    const href = el.getAttribute("href") || "";
    return {
      event,
      from: el.getAttribute("data-lcv-from") || "",
      success: el.getAttribute("data-lcv-to-success") || href,
      fail: el.getAttribute("data-lcv-to-fail") || "",
      interrupted: el.getAttribute("data-lcv-to-interrupted") || "",
      disabled: Boolean(el.disabled),
      linked: Boolean(event) || (el.tagName === "A" && href.length > 0),
    };
  };
  for (const el of document.querySelectorAll("[data-lcv-event]")) {
    const edge = readEdge(el);
    interact.push(edge);
    seenInteract.add(el);
  }
  for (const root of document.querySelectorAll("[data-lcv-machine]")) {
    for (const el of root.querySelectorAll("button, a")) {
      if (seenInteract.has(el)) continue;
      const edge = readEdge(el);
      interact.push(edge);
      if (!edge.linked) {
        pushNode(el.id || `interact-${nodes.length}`, el.tagName.toLowerCase(), el, "interact");
        nodes[nodes.length - 1].linked = false;
      }
    }
  }

  const layoutFromSegments = (segments, maxWidth, lineHeight) => {
    const width = Math.max(0, Number(maxWidth) || 0);
    const lh = Number(lineHeight) || 0;
    if (!segments.length) return { lineCount: 0, height: 0 };
    let lineW = 0;
    let lineCount = 1;
    for (const seg of segments) {
      const w = Number(seg.w) || 0;
      if (lineW > 0 && lineW + w > width) {
        lineCount += 1;
        lineW = w;
      } else {
        lineW += w;
      }
    }
    return { lineCount, height: lineCount * lh };
  };
  const textHeightIn = (root, maxWidth) => {
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");
    if (!ctx) return null;
    let height = 0;
    const blocks = root.querySelectorAll("h1, h2, h3, p, li, blockquote, [data-lcv='must-show']");
    for (const el of blocks) {
      const raw = (el.innerText || "").replace(/\s+/g, " ").trim();
      if (!raw) continue;
      const style = getComputedStyle(el);
      ctx.font = style.font;
      const parsedLh = Number.parseFloat(style.lineHeight);
      const lineHeight =
        Number.isFinite(parsedLh) && style.lineHeight !== "normal"
          ? parsedLh
          : Number.parseFloat(style.fontSize) * 1.25;
      const segments = raw.split(/(\s+)/).map((part) => ({ w: ctx.measureText(part).width }));
      height += layoutFromSegments(segments, maxWidth, lineHeight).height;
    }
    const pad = getComputedStyle(root);
    height += (Number.parseFloat(pad.paddingTop) || 0) + (Number.parseFloat(pad.paddingBottom) || 0);
    return height;
  };
  const beat = document.querySelector("[data-lcv-fit='beat']");
  const slot = beat?.closest("[data-lcv-slot='beat']") || beat?.parentElement;
  let fit = null;
  if (beat && slot) {
    const remaining = { w: slot.clientWidth, h: slot.clientHeight };
    const fromFont = textHeightIn(beat, remaining.w);
    let fontPx = Number.parseFloat(getComputedStyle(beat).fontSize);
    for (const el of beat.querySelectorAll("[data-lcv='must-show']")) {
      const px = Number.parseFloat(getComputedStyle(el).fontSize);
      if (Number.isFinite(px) && px < fontPx) fontPx = px;
    }
    fit = {
      kind: "beat",
      engine: fromFont == null ? "box" : "font-engine",
      remaining,
      contentMin: {
        w: remaining.w,
        h: fromFont == null ? beat.scrollHeight : fromFont,
      },
      fontPx: Number.isFinite(fontPx) ? fontPx : undefined,
    };
  }

  const root = document.documentElement;
  const view = { w: window.innerWidth, h: window.innerHeight };
  return {
    landmarks,
    document: boxOf(root),
    view,
    layoutMode: {
      w: view.w,
      h: view.h,
      orientation: view.h >= view.w ? "portrait" : "landscape",
    },
    uiState,
    states: listed.length ? listed : uiState ? [uiState] : [],
    machines: machineNodes,
    interact,
    fit,
    nodes,
  };
}
