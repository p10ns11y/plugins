/**
 * Glyph-then-arithmetic text layout (Pretext technique).
 * prepare: measure segment widths (Canvas measureText / font engine).
 * layout: wrap by summing widths. No getBoundingClientRect.
 * Full engine: @chenglou/pretext (https://pretextjs.dev/ https://github.com/chenglou/pretext).
 */

export function layoutFromSegments(segments, maxWidth, lineHeight) {
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
}

export function segmentsFromWidths(widths) {
  return widths.map((w) => ({ w: Number(w) || 0 }));
}
