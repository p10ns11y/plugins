# IntelliArch stack

Portable entry for hosts that read `AGENTS.md`.

Machine-readable composition: [manifest.json](manifest.json). Install and limits: [README.md](README.md).

Skill procedures: https://github.com/p10ns11y/skills (`master`). Do not copy them here.

## Load

Read `manifest.json`. Open each `repo` + `path`. Do not paste bodies into the turn.

1. A dumped prompt goes through `control-feeder` first. It emits a Feed and one next owner.
2. Non-trivial engineering loads `pstack-map`, then installed pstack (`poteto-mode`) when the playbook exists on this host. Otherwise use the house skill named in `pstack-map` `references/map.md`.
3. Multi-step work opens a control-graph Card. Budgets and HITL live there.
4. Emptiness (no map, unknowns dominate) loads `eva-emptiness` as the inner loop. The outer phases stay in control-graph.
5. Plans and reviews load `odysseus-navigator` for one mistake and one next act.
6. Style loads `peram_senior_mlai_engineer` from the skills repo by path.

## Adjustment

On Cursor, model seats stay in `~/.cursor/rules/pstack-models.mdc`. This stack does not write that file.

On every other host, simulate control-graph roles with phase prompts. Reset context for review. `inherit-parent` means the host's current model.

## Pause

Pause before secrets, production, irreversible git, CV promote, unknown auth, and money, legal, or health acts.

## Credit

Playbook names and principle files are Lauren Tan / pstack, MIT. House skills stay in `p10ns11y/skills` and sibling plugins in this repo.

Request flow, the model rule, and `orch` / `watch-pr` are the IntelliArch engineering note (`pstack-engineering.md`). This file does not paste that essay.
