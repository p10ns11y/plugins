# intelli-route

Routes one goal onto at most four skills that already exist. pstack supplies the playbook when it is installed ([Lauren Tan, MIT](https://github.com/cursor/plugins/tree/main/pstack)). Otherwise the house row in [pstack-map](../pstack-map/skills/pstack-map/references/map.md) does. This tree does not copy skill bodies and it does not vendor pstack.

The contract is [manifest.json](manifest.json). A host that opens every path in that file is not using it.

## Decide

A paste or dump with no single ask goes through `control-feeder`. Then the first match wins:

| Match | Route | Load |
|---|---|---|
| No map, unknowns dominate, authorization is the unknown, or a multi-session effort whose route is still fog | `empty` | `eva-emptiness` in this repo (`eva-emptiness/skills/eva-emptiness/SKILL.md`). The skills-repo entry is a sibling symlink and 404s on GitHub. |
| Multi-step, until-done, or the same step is being redone | `card` | `control-graph` |
| Otherwise | `light` | `pstack-map`, then one playbook or the house row |

Add a signal only when its `when` matches: `odysseus-navigator`, `ai-optimization`, `agent-orchestrator`, `git-worktrees`, `adversarial-audit`, `pulse-memory`, `mission-map`, `uncertainty-laws`, `layout-content-view`, `premflow`, `arch-machine`, `peram_senior_mlai_engineer`, `peram_data_workflows`, `peram_si_native_workflows`, `peram_si_service_harness`, `peram_deterministic_saas`, `peram_infra`, `peram_devex`, `split-machine`, `trust-stack`, `steer-log`, `steer-accel`, `concordance`, `master-planner`, `higher-order-decision-architect`, `stellar-spacemap`, `architecture-synthesis`, `craft`. Stop at four loads. `clt-dual-load` is a host rule. Do not paste it and do not count it.

Upstream alignment names stay upstream. Fog across sessions loads `eva-emptiness`, then `mission-map` once the destination is named. An alignment interview loads `steer-log` and ends when the invariant card is admitted. A settled conversation that needs a spec loads `craft`. Blocking tickets load `mission-map`, and each builder card still goes through `steer-log`. A glossary loads `architecture-synthesis`. A session lookback loads `trust-stack`. A resume on the same harness and directory loads `steer-accel`. A resume that changes harness or directory loads `pulse-memory`. A task graph loads `git-worktrees`. Do not fetch those bodies.

## Upstream

Catalog: [AI Skills for Real Engineers](https://www.aihero.dev/skills). Source: [mattpocock/skills](https://github.com/mattpocock/skills). The bodies stay there.

| Page | House |
|---|---|
| [wayfinder](https://www.aihero.dev/skills-wayfinder) | `eva-emptiness`, then `mission-map` |
| [grill-with-docs](https://www.aihero.dev/skills-grill-with-docs) | `steer-log`; overbuilding returns through `odysseus-navigator` |
| [to-spec](https://www.aihero.dev/skills-to-spec) | `craft` |
| [to-tickets](https://www.aihero.dev/skills-to-tickets) | `mission-map`, then a builder card through `steer-log` |
| [domain-modeling](https://www.aihero.dev/skills-domain-modeling) | `architecture-synthesis` |
| [retro](https://www.aihero.dev/skills-retro) | `trust-stack`, then `findings-first` |
| [handoff](https://www.aihero.dev/skills-handoff) | `steer-accel` on the same harness and directory; `pulse-memory` when either changes |
| [implement-spec](https://www.aihero.dev/skills-implement-spec) | `shared-scripts` and `git-worktrees` |
| [writing-for-agents](https://www.aihero.dev/skills-writing-for-agents) | `workflow-skills` |
| [pr](https://www.aihero.dev/skills-pr) | pull request template, `scaled-verifiers`, `pstack-map` shipping row |

## How the three stacks meet

This marketplace is the control plane. [pstack](https://github.com/cursor/plugins/tree/main/pstack), by Lauren Tan, is the execution playbook once the work has a name. [AI Hero](https://www.aihero.dev/skills), by Matt Pocock, is the alignment chain for one product repo, from a shared understanding through a spec, tickets, a build, a review, and a lookback. They meet here: at most four loads, the pstack body when it is installed, otherwise the house row. AI Hero bodies stay on [aihero.dev/skills](https://www.aihero.dev/skills).

A stretch runs in that order. Fog stays `eva-emptiness`. A closed decision is a `steer-log` card. The path is `mission-map`. This router picks the loads. The build is pstack or `craft`. A break on the same harness reads `steer-accel`. A lookback is `trust-stack`. The pull request uses the house shape.

On an overlap, load the row with the stronger claim. That is the better chance the check already exists here. It is not a calibrated probability. The System One section below says the same about `confidence`.

| Overlap | Stronger claim | Why that claim wins |
|---|---|---|
| Multi-session fog | `eva-emptiness` | The emptiness loop and the auth tether already run. [wayfinder](https://www.aihero.dev/skills-wayfinder) stays the upstream name. Hand off to `mission-map` once the destination is named. |
| Alignment interview | `steer-log` | The card line needs a failing command, and `bin/steer-log` admits or refuses. [grill-with-docs](https://www.aihero.dev/skills-grill-with-docs) stays upstream. |
| Interview starts overbuilding | `odysseus-navigator` | Name the overbuild, cut once, return to the card. |
| Settled conversation to a spec | `craft` | Specifier, then CRAP, mutation, and Bend on the touched code. [to-spec](https://www.aihero.dev/skills-to-spec) stays upstream. |
| Blocking tickets | `mission-map` | Critical path, bands, and what each Do blocks. A builder card still goes through `steer-log`. [to-tickets](https://www.aihero.dev/skills-to-tickets) stays upstream. |
| Glossary | `architecture-synthesis` | Domain words and a hard-to-reverse decision. `pulse-memory` admits contradictions. |
| Session lookback | `trust-stack` | Earliest layer: a mechanical miss becomes `check` or `watch`, a judgment miss stays `skill` or `guide`. A person picks the row. `findings-first` appends it. [retro](https://www.aihero.dev/skills-retro) stays upstream. |
| Resume, same harness and directory | `steer-accel` | The stage log is what the next session reads. [handoff](https://www.aihero.dev/skills-handoff) stays upstream. |
| Resume, harness or directory changes | `pulse-memory` | One tagged snippet points at the log and the spec. The traveling file stays out of the repo. |
| Task graph of tickets | `shared-scripts` and `git-worktrees` | One deterministic script runs each ready ticket. Parallel tickets use separate worktrees. [implement-spec](https://www.aihero.dev/skills-implement-spec) stays upstream. |
| Named engineering (bug, feature, test-first, review) | pstack when installed, else the [house row](../pstack-map/skills/pstack-map/references/map.md) | The playbook is the execution pass. `craft` still owns spec-before-code and the scores. One test-first owner per task. |
| Pull request body | house template, then the pstack shipping row | A picture, a before and an after, then a one-way or two-way door and the blast radius. [pr](https://www.aihero.dev/skills-pr) stays upstream. |
| Writing a skill | `workflow-skills` | A user-invoked skill orchestrates. A model-invoked skill holds the discipline. Load the other skill by the skill tool. [writing-for-agents](https://www.aihero.dev/skills-writing-for-agents) stays upstream. |
| Which skill to load | `intelli-route` | This router already caps the loads at four. [ask-matt](https://www.aihero.dev/skills-ask-matt) stays upstream. |

Leave upstream, with no house copy: triage, wizard, teach, wait-what, and a throwaway prototype. A UI question uses `layout-content-view`. A pstack `prototype` playbook covers a throwaway that must not ship.

`hitl` is required for secrets, production, irreversible git, CV promote, unknown authorization, and money, legal, or health acts. On HITL, emit the route and stop. Reversible edits proceed.

## Emit, then act

```markdown
## Intelli-route
| Field | Value |
|-------|--------|
| **situation** | |
| **route** | light \| card \| empty |
| **loads** | |
| **skips** | |
| **playbook** | |
| **hitl** | none \| required (reason) |
| **next** | one action |
```

`light` takes that playbook's first bounded step. `card` names a phase, a budget, and one verify command, then does only the current phase. `empty` writes knowns, unknowns, one idk, `disprove_with`, and ActOrAsk. Unknown authorization stays Ask.

## System One shape

The card is the kind of decision System One is for: one goal in, a closed `route`, at most four `loads`, and a `confidence` the script can branch on. Low confidence stays read-only.

Classify is still an agent. The confidence is a word that agent picks. It is not a calibrated probability, and this plugin does not call [Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev). A later host may fill the same card from a System One model. Until then, the act step stays the slow work.

A closed decision that must be corroborated loads `concordance`. This card does not compare the two labels.

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install intelli-route --trust
# or local:
grok plugin install ./intelli-route --trust
```

Dev symlink:

```bash
mkdir -p ~/.grok/plugins
ln -sfn "$(pwd)/intelli-route" ~/.grok/plugins/intelli-route
```

Also install **pstack** for `/poteto-mode`, and **pstack-map** from this repo. Clone [p10ns11y/skills](https://github.com/p10ns11y/skills) where the host already loads skills. Do not copy those files into this plugin.

Workflows are not auto-registered. The script enforces the four-load cap. A slash command relies on the model to obey it.

```bash
cp intelli-route/.grok/workflows/intelli-route.rhai ~/.grok/workflows/
```

## Use

| Surface | How |
|---|---|
| Grok | `/intelli-route <goal>` · `/workflow intelli-route {"goal":"…"}` |
| Cursor | copy `cursor/rules/intelli-route.mdc` into `.cursor/rules/`. Leave `pstack-models.mdc` as `/setup-pstack` wrote it. `/poteto-mode` still runs the one playbook. |
| Bot | paste [bot/intelli-route.md](bot/intelli-route.md) as the system card. No webhook. |
| Other hosts | [AGENTS.md](AGENTS.md) plus the skills checkout on that host's skill path. |

On Grok, Bot, and other hosts, model seats are `fast`, `explore`, `coding`, `deep`, and `review`. Review uses a fresh context.

## Layout

```text
plugin.json
LICENSE
NOTICE.md
README.md
manifest.json
AGENTS.md
commands/intelli-route.md
cursor/commands/intelli-route.md
cursor/rules/intelli-route.mdc
.grok/workflows/intelli-route.rhai
bot/intelli-route.md
agents/intelli-route.md
test/test-thin.sh
```

No `skills/` directory. Procedures live upstream.

## Platform limits

| Mechanism | Cursor | Grok Build | Bot | Other |
|---|---|---|---|---|
| Playbook bodies | pstack plugin | only if pstack is installed; else house row | same as Grok | same as Grok |
| Per-slug model file | `pstack-models.mdc` | roles only | roles only | roles only |
| `poteto-agent`, Comment Sicko | yes | no | no | no |
| `orch` / `watch-pr` | yes; watcher is GitHub | no | no | no |
| Graphite land | pstack shipping path | pause for a human | pause | pause |
| EVA tether hooks | install `eva-emptiness` | same | ask in the card | ask |
| Rhai workflow | ignore | copy into a workflows root | ignore | ignore |
| premflow | skill text only | needs `premflow` on `PATH` | skill text only | skill text only |
| mission-map kernels | optional local `make` / `cargo` | same | narrative map only | same |

## Tests

```bash
./intelli-route/test/test-thin.sh
```

The thin test checks the route contract, resolves every manifest path, and runs the Bend proof of the trust laws when Bend is installed (`bend` or `~/.bend/bin/bend`).
