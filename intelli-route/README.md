# intelli-route

Routes one goal onto at most four skills that already exist. pstack supplies the playbook when it is installed ([Lauren Tan, MIT](https://github.com/cursor/plugins/tree/main/pstack)). Otherwise the house row in [pstack-map](../pstack-map/skills/pstack-map/references/map.md) does. This tree does not copy skill bodies and it does not vendor pstack.

The contract is [manifest.json](manifest.json). A host that opens every path in that file is not using it.

## Decide

A paste or dump with no single ask goes through `control-feeder`. Then the first match wins:

| Match | Route | Load |
|---|---|---|
| No map, unknowns dominate, or authorization is the unknown | `empty` | `eva-emptiness` in this repo (`eva-emptiness/skills/eva-emptiness/SKILL.md`). The skills-repo entry is a sibling symlink and 404s on GitHub. |
| Multi-step, until-done, or the same step is being redone | `card` | `control-graph` |
| Otherwise | `light` | `pstack-map`, then one playbook or the house row |

Add a signal only when its `when` matches: `odysseus-navigator`, `ai-optimization`, `agent-orchestrator`, `git-worktrees`, `adversarial-audit`, `pulse-memory`, `mission-map`, `uncertainty-laws`, `layout-content-view`, `premflow`, `arch-machine`, `peram_senior_mlai_engineer`, `split-machine`, `trust-stack`, `master-planner`, `higher-order-decision-architect`, `stellar-spacemap`, `architecture-synthesis`. Stop at four loads. `clt-dual-load` is a host rule. Do not paste it and do not count it.

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
