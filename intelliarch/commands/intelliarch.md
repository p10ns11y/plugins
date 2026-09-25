---
description: Compose pstack (Lauren Tan, MIT) with house skills. Read manifest.json. Do not paste or copy bodies.
argument-hint: goal or dumped prompt
---

# /intelliarch

Read `manifest.json` in this plugin. Open each `repo` + `path`. Do not paste bodies. Do not copy pstack files.

## Immediate actions

1. If the user text is a dump, follow `control-feeder` and emit Feed.
2. Follow `pstack-map`. If pstack is installed, load that playbook. If it is missing, use the house row in `references/map.md`.
3. Multi-step: open a control-graph Card and set budgets before tools.
4. Emptiness gate from `eva-emptiness` when unknowns dominate. Stay on ask. Do not pass `--always-approve` or `--yolo`.
5. On a plan or review, emit a Navigator row from `odysseus-navigator`.
6. Model seats: host default. Use control-graph roles `fast`, `explore`, `coding`, `deep`, `review`. Reset context for review.
7. `hitl=required` for secrets, prod, irreversible git, CV, unknown auth, money, legal, or health.

Goal:

```text
$ARGUMENTS
```

Credit: Lauren Tan / pstack MIT when a pstack playbook runs.
