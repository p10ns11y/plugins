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

`deep` = planner (keep the pool, strongest first). `review` = judge (one rung down the same family only if confirmed in session; else keep as-is).

## Snapshot fallback (pstack 0.15.32 · read 2026-10-26)

From [setup-pstack/SKILL.md](https://github.com/cursor/plugins/blob/e73df471cd4bd918367e99f3dd9c51bd53ddf5f0/pstack/skills/setup-pstack/SKILL.md) at upstream commit `e73df471`. Re-check upstream when this drifts.

```
# budget: large (xhigh)
feature, refactoring: grok-4.7-xhigh-fast
bug-fix: grok-4.7-xhigh-fast
perf-issue: grok-4.7-xhigh-fast
hillclimb: grok-4.7-xhigh-fast
judgment and prose: claude-opus-5-5-xhigh
hardest tasks: claude-opus-5-5-xhigh
how explorer: grok-4.7-xhigh-fast
how explainer: claude-opus-5-5-xhigh
why investigators: grok-4.7-xhigh-fast
why synthesizer: claude-opus-5-5-xhigh
reflect tooling: grok-4.7-xhigh-fast
reflect judgment, divergent, synthesizer: claude-opus-5-5-xhigh
arena runners: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
arena cross-judge pool: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
swarm workers: grok-4.7-xhigh-fast
architect runners: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
interrogate reviewers: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
```

Budget ladder (upstream): `unlimited` → max; `large` → xhigh; `medium` → high; `small` → medium. Grok slugs top out at `xhigh`.

## Plan strong, judge cheap

Sakana MASS: upgrading the planner helps much more than upgrading the judge.

`pstack-models.mdc` role lines win when present. Apply the lists below only on the snapshot fallback, or when the user asks. Do not rewrite that file.

Planner: keep each pool and order it strongest first (higher budget-ladder rung before a lower one; a shared rung keeps snapshot order). Roles: `architect runners`, `hardest tasks`, `how explainer`, `why synthesizer`, `judgment and prose`.

Judge: keep the pool. Step each slug one rung down the upstream budget ladder, same family (max → xhigh). Use the stepped slug only if this session confirms it; otherwise keep the listed slug. Roles: `arena cross-judge pool`, `interrogate reviewers`, `reflect judgment, divergent, synthesizer`.
