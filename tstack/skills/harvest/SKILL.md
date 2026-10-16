---
name: harvest
description: Turn block evidence into a shared state row. Public log row only when a path is named. No personal figures in public rows.
---

# harvest

1. Evidence is a link, a sent-draft id, a merged SHA, or a signpost. No evidence, no row.
2. `tstack-state harvest add --map <id> --stage <id> --result <text> --evidence <text>`, then `tstack-state block close --map <id>`.
3. Append one public row only when the operator names a path. `bin/public-row` writes that file. Money, health, and family figures stay out of that file and out of `result`.
4. If `premflow` is on PATH: `premflow win <text>` and `premflow task done <n>`. If it is missing, `bin/premflow-path` prints one line that points at `premflow/README.md`, and the loop continues.
5. Load pulse-memory once, then mission-map, to admit the row and mark the stage Done.
