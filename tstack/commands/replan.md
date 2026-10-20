---
description: Sweep inputs and re-run the remaining DAG after a shock
argument-hint: "[shock]"
---

# /replan

1. Load skill **capture-sweep**.
2. Load **mission-map** and re-run the remaining DAG only. `$ARGUMENTS` is the shock.
3. Emit the next Do. Start nothing; `/tomato` starts the block.

Before choosing, run `tstack-state resume` and `bin/capture-sweep pr-age`. `pr-age` lists every open pull request and draft by age even with no new event, classed blocked-on-user, resume, blocked-on-party (ask after 72h) or propose-close (idle 7 days; never auto-close). A resume class outranks new work.
