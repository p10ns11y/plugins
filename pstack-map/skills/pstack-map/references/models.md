# Model resolution

Playbook bodies stay upstream. This file is only for **which model** each pstack role uses.

## Cursor (Task `model` slugs)

1. If `~/.cursor/rules/pstack-models.mdc` exists, read it. Treat each role line and the `# budget` line as the live choices. Do not rewrite that file from pstack-map.
2. Else use the upstream defaults in [setup-pstack step 5](https://github.com/cursor/plugins/blob/main/pstack/skills/setup-pstack/SKILL.md) (or the dated snapshot below).

Never pass a slug you have not confirmed is available in this session. `inherit-parent` and `auto` are always valid.

## Non-Cursor hosts (control-graph fallback)

Hosts without Cursor Task model lists keep four CG roles. Map each to a pstack role, then resolve the model from the steps above:

| CG role | pstack role |
|---------|-------------|
| fast | hillclimb |
| coding | refactoring |
| deep | hardest tasks |
| review | reflect judgment, divergent, synthesizer |

## Snapshot fallback (pstack 0.15.7 · read 2026-10-03)

From [setup-pstack/SKILL.md](https://github.com/cursor/plugins/blob/9511e60321f7e533a187d62854a3d53a53752874/pstack/skills/setup-pstack/SKILL.md) at upstream commit `9511e603`. Re-check upstream when this drifts.

```
# budget: unlimited (max)
feature, refactoring: grok-4.7-xhigh-fast
bug-fix: grok-4.7-xhigh-fast
perf-issue: grok-4.7-xhigh-fast
hillclimb: grok-4.7-xhigh-fast
judgment and prose: claude-opus-5-5-max
hardest tasks: claude-opus-5-5-max
how explorer: grok-4.7-xhigh-fast
how explainer: claude-opus-5-5-max
why investigators: grok-4.7-xhigh-fast
why synthesizer: claude-opus-5-5-max
reflect tooling: gpt-5.6-sol-max
reflect judgment, divergent, synthesizer: claude-opus-5-5-max
arena runners: claude-opus-5-5-max, gpt-5.6-sol-max, grok-4.7-xhigh-fast
arena cross-judge pool: claude-opus-5-5-max, gpt-5.6-sol-max, grok-4.7-xhigh-fast
swarm workers: grok-4.7-xhigh-fast
architect runners: claude-opus-5-5-max, gpt-5.6-sol-max, grok-4.7-xhigh-fast
interrogate reviewers: claude-opus-5-5-max, gpt-5.6-sol-max, grok-4.7-xhigh-fast
```

Budget ladder (upstream): `unlimited` → max; `large` → xhigh; `medium` → high; `small` → medium.
