# Sitemap / view graph

Not `sitemap.xml`. That file (if any) is for crawlers; this graph is for **layout regions**.

```text
Rel    ∈ { contains, indexes, flows }
Region = { id, role: LandmarkRole | lcv-role, sel?, mustShow: bool }
ViewGraph = { path, nodes: Region[], edges: { from, to, rel }[] }
```

## Sources (priority)

1. Project verify feature map: `path:` frontmatter only (devprofile: `.cursor/skills/verify-devprofile/features/*.md`).
2. HTML landmarks after load: `main`, `h1`, `nav`, `[data-lcv]`.
3. Optional: existing `sitemap.xml` / `llms.txt` as **extra index edges**, never as geometry.

Do not mint a TypeScript `SURFACES[]` that duplicates (1).

## Crawlable

`crawlable(landmarks)` in `scripts/lcv.mjs`: `main` ∧ heading ∧ (navigation ∨ skip).

Agents index what they can reach from the graph. A clipped must-show node is not crawlable even if the URL is.
