---
description: Route one goal onto at most four skills (pstack or the house row). Emit the route, then do that one next step.
argument-hint: goal or dumped prompt
---

# /intelli-route

Read `manifest.json` in this plugin. It is the contract. Do not open every path in it.

`$ARGUMENTS` is the goal. If it is empty, use the current turn.

## Decide

A paste or dump with no single ask goes through `control-feeder` first. Then the first match wins:

1. No map, unknowns dominate, or authorization is the unknown → route `empty`. Load `eva-emptiness`.
2. Multi-step, until-done, or the same step is being redone → route `card`. Load `control-graph`.
3. Otherwise → route `light`. Load `pstack-map`, then one installed pstack playbook or the house row in `pstack-map/skills/pstack-map/references/map.md`.

Add a signal load only when its `when` matches. Stop at four loads, including the primary. `clt-dual-load` is a host rule. Do not paste it and do not count it.

`hitl` is required for secrets, production, irreversible git, CV promote, unknown authorization, and money, legal, or health acts. On HITL, emit the table and stop.

## Emit, then act

Write this table before any edit:

```markdown
## Intelli-route
| Field | Value |
|-------|--------|
| **situation** | |
| **route** | light \| card \| empty |
| **loads** | |
| **skips** | ids considered and dropped, with a reason |
| **playbook** | name or skip |
| **hitl** | none \| required (reason) |
| **next** | one action |
```

Then do only `next`:

- `light` — that playbook's first bounded step. Reversible edits may proceed. Run a real check if you changed files.
- `card` — phase, budget, verify command, and only the current phase.
- `empty` — knowns, unknowns, one idk, `disprove_with`, and ActOrAsk. Unknown authorization stays Ask. Do not pass `--always-approve` or `--yolo`.

Roles are `fast`, `explore`, `coding`, `deep`, `review` on the host model. Review uses a fresh context.

Credit Lauren Tan / pstack MIT when a playbook runs. Do not copy pstack or skills-library files into this repo. Do not rewrite `pstack-models.mdc`.

Goal:

```text
$ARGUMENTS
```
