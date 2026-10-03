# NOTICE

Copyright (c) 2026 p10ns11y. MIT. See `LICENSE`.

These habits are distilled from a [live conversation with Lauren Tan](https://www.youtube.com/watch?v=MN9dGgmLyso), hosted by Matt Pocock. Timestamps are approximate (±30 s) and match the published video.

Five habits include **our adaptations**, not claims Lauren Tan made: `shared-scripts`, `findings-first`, `events-over-timers`, `scaled-verifiers`, and `kitchen-time`.

`shared-scripts` (~21:00–24:00): agents kept rebuilding verification glue; deterministic parts went into a CLI inside the skill (~23:30). JSON stdout, a separate scripts index, and no LLM in the checker are ours.

`findings-first` (~48:00): append observations to a document; review every few days; cluster before fixing. Writing to the file before pinging anyone, and a pointer-only notification, are ours.

`events-over-timers`: stop ferrying Slack, mail, and bug reports by hand (~35:00–38:00). Wire subscriptions so agents pull context (~36:30–37:30). A coordinator delegates when many issues arrive at once (~43:30–44:30). At ~47:30 she also has timer routines ("I have some routines like that as well"). Prefer events first, use a timer only when no event surface exists, and retire cron when an event path covers the same signal: that ranking is ours. The findings document at ~47:30–48:30 is a code-scanning routine, not burst buffering.

`workflow-skills` (~1:04:00): older skills were "almost like implementation details" with exact commands; delete those and "really focus on the workflow."

`repeat-or-leave` (~50:30–51:00): when sampling pull requests, a one-off bad pattern may mean "maybe there's nothing to fix there." When multiple agents repeat the same shortcut, amend skills, constraints, and lint.

`scaled-verifiers`: sampling instead of tasting every dish (~49:30–50:00); "instead of like 10 verifier agents, you might do like one" (~53:30). On irreversible work she had no general recipe; it depends on whether agents can truly verify the domain (~56:30–57:00). The risk ladder is ours.

`kitchen-time` (~26:30–28:30): stuck micromanaging agents because the kitchen was never set up — dull knives, no garlic press. (~46:00): many PRs are gardening and environment work. No calendar slice was prescribed. The prompt to invest before scaling is ours.

**pstack** is [Lauren Tan's Cursor plugin](https://github.com/cursor/plugins/tree/main/pstack) (poteto, MIT). This repo ships **pstack-map**, not pstack itself.

This plugin does not merge pull requests.
