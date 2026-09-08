# Link to mission-map

**Do not fuse the plugins.** They answer different questions.

| Plugin | Owns | Does not own |
|--------|------|--------------|
| **mission-map** | \(G\), DAG, critical path, Do/Risk/Wait/Park, PERT bands, replan on shock | Bet-size napkin, Bayes on a single piece of evidence |
| **uncertainty-laws** | EV / base rate / ruin / Kelly on **one** fork | Rewriting the DAG or inventing stages |

## When to chain

1. Build or refresh the map with `/mission-map`.
2. On the **next Do** or a hot **Risk**, run `/uncertainty-laws` on that fork only.
3. Write `mm_hook` = node id + class.
4. If Law 3 says ruin, reclass or mitigate on the map (human confirms) — do not silently edit \(a/m/b\).

## Class ↔ law cheat sheet

| mission-map class | uncertainty-laws tendency |
|-------------------|---------------------------|
| **Do** | Pass 1–3, then Kelly-size the hours/cash |
| **Risk** | Law 2–3 first; signpost before size |
| **Wait** | Often `nothing-now` until signpost |
| **Park** | Refuse; Law1 against or ∇T ≈ 0 |

## Shock rule (shared)

On outside shock: re-run remaining DAG (**mission-map**), then napkin the new next fork (**uncertainty-laws**). Do not add a fifth mission for optics.
