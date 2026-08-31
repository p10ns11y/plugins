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
  const uiState =
    document.querySelector("[data-lcv-machine='profile-deck']")?.getAttribute("data-lcv-ui-state") ||
    document.querySelector("[data-lcv-ui-state]")?.getAttribute("data-lcv-ui-state") ||
    "";
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
    interact,
    nodes,
  };
}
