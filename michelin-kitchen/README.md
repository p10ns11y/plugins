# michelin-kitchen

Seven habits for running agent work like a professional kitchen. Grounded in a [live conversation](https://www.youtube.com/watch?v=MN9dGgmLyso) with **Lauren Tan**, hosted by **Matt Pocock**.

Pick the habits you need. The talk's own metaphor is a chef who brings their own knives to a new restaurant (~1:01:30).

## Caveats from the talk

- Lauren Tan: "I don't want to sell this as something that you can just do easily by using pstack" (~51:30). **pstack** is [Lauren Tan's Cursor plugin](https://github.com/cursor/plugins/tree/main/pstack) (poteto, MIT). This repo ships **pstack-map** when pstack is installed. Neither promises her production volume.
- Lauren Tan (~1:01:30–1:02:30): "everyone should have their own set of knives"; trust as "trust in your own tools". Combine pstack, Matt Pocock's skills and your own, and mine your past transcripts for the times you corrected an agent.

## Habits

| Skill | Source | Talk (approx.) |
|---|---|---|
| [shared-scripts](skills/shared-scripts/SKILL.md) | Lauren Tan + ours | ~21:00–24:00, CLI inside the skill ~23:30. JSON stdout, a scripts index, and no LLM in the checker are ours |
| [findings-first](skills/findings-first/SKILL.md) | Lauren Tan + ours | ~48:00 — append to a document; review every few days; cluster before fixing. Before-ping and pointer-only are ours |
| [events-over-timers](skills/events-over-timers/SKILL.md) | Lauren Tan + ours | ~35:00–38:00 outer loop; ~36:30–37:30 subscriptions; ~43:30–44:30 bursts to a coordinator; ~47:30 she also has timer routines ("I have some routines like that as well") — ranking timers last is ours. ~47:30–48:30 findings are code-scanning, not burst buffering |
| [workflow-skills](skills/workflow-skills/SKILL.md) | Lauren Tan | ~1:04:00 — "almost like implementation details"; "really focus on the workflow" |
| [repeat-or-leave](skills/repeat-or-leave/SKILL.md) | Lauren Tan | ~50:30–51:00 — "maybe there's nothing to fix there." Repeats across agents: amend the kitchen |
| [scaled-verifiers](skills/scaled-verifiers/SKILL.md) | **Our adaptation** | ~49:30–50:00 sampling; ~53:30 "instead of like 10 verifier agents, you might do like one"; ~56:30–57:00 one-way doors depend on verifiability. The risk ladder is ours |
| [kitchen-time](skills/kitchen-time/SKILL.md) | **Our adaptation** | ~26:30–28:30 dull knives, no garlic press; ~46:00 gardening PRs. No prescribed time slice |

## Overlap with other plugins

| Plugin | Use instead of duplicating |
|---|---|
| `trust-stack` | Earliest layer for an invariant (`repeat-or-leave`) |
| `intelli-route` | Route a goal; outer-loop handoff (`events-over-timers`) |
| `pulse-memory` | Tagged sparse memory vs transcript dumps (`findings-first`) |
| `premflow` | Capture after a findings review |
| `mission-map` | When the queue needs a map, not a script |
| `pstack-map` | Playbook map when pstack is installed |
| `steer-log` | An alignment interview ends when the invariant card is admitted |
| `craft` | A settled conversation becomes a spec before code |
| `steer-accel` | Same harness and directory: the stage log is the resume |

Upstream pages, bodies stay there: [writing-for-agents](https://www.aihero.dev/skills-writing-for-agents), [implement-spec](https://www.aihero.dev/skills-implement-spec), [pr](https://www.aihero.dev/skills-pr), catalog [AI Skills for Real Engineers](https://www.aihero.dev/skills).

## Install

```bash
grok plugin install ./michelin-kitchen --trust
# slash: /michelin-kitchen <habit>
```

## Tests

```bash
./michelin-kitchen/test/test-thin.sh
```

Eval dataset: [evals/evals.json](evals/evals.json). Cases are checkable pass/fail prompts; run manually or wire into SkillEvaluator when a runner exists for this plugin.

Talk credit: [NOTICE.md](NOTICE.md).
