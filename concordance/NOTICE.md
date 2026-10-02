# NOTICE

Copyright (c) 2026 p10ns11y. MIT. See `LICENSE`.

Concordance is a local check. A decision model proposes one closed label. An LLM confirms one closed label. The act is `proceed` only when those labels are the same token and `p_dm` is greater than or equal to the caller's `tau`. Every other case is `hold`.

The typed decision this check sits beside is the shape described by TypeSafe AI in [Introducing System One Models & Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev). This plugin does not call that API, ship that model, or claim those benchmarks.

`kappa_window`, when the caller supplies a window of recent cases, is Cohen's kappa on that window. This plugin does not ship a stats library and does not invent the count.

This tree is a procedure. It is not a second router and it is not a judge model.
