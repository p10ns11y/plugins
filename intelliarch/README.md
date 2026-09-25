# intelliarch

pstack owns the playbook and, on Cursor, the per-role model file. This plugin loads skills that already exist for the gaps around that: a dump is rewritten before a playbook, multi-step work gets budgets and a pause on irreversible acts, a missing map gets an emptiness loop, and plans get a judgment pass.

Composition: [manifest.json](manifest.json). Skill bodies stay in [p10ns11y/skills](https://github.com/p10ns11y/skills). This tree does not copy them. pstack stays upstream ([Lauren Tan, MIT](https://github.com/cursor/plugins/tree/main/pstack)). This plugin does not vendor it.

Request flow, the `pstack-models.mdc` rule, and `orch` / `watch-pr` are the IntelliArch engineering note (`pstack-engineering.md`). This README does not paste that essay.

## What runs

| Situation | Load | Stays in pstack |
|---|---|---|
| Pasted dump | `control-feeder` | |
| Engineering task | `pstack-map`, then `poteto-mode` if installed | playbook steps, principles, how / why / architect / arena / swarm / interrogate |
| Multi-step or "until done" | `control-graph` Card | |
| Unknowns dominate | `eva-emptiness` inner loop | |
| Plan or architecture review | `odysseus-navigator` | |
| Context is large | `ai-optimization` before the deep fill | |
| Parallel writers | `git-worktrees` plus `agent-orchestrator` | |
| Review where Task model seats are missing | `adversarial-audit` | `interrogate` when Cursor Task works |
| Contradicting notes | `pulse-memory` | `recall` for chat rebuild |
| Critical path or shock | `mission-map` | |
| Bet, money, or ruin | `uncertainty-laws` (EV, then base rate, then ruin, then Kelly) | |
| Clip, overflow, landmarks | `layout-content-view` | `visual-parity` for pixels |
| Note, win, journal, focus | `premflow` | |
| Host audit | `arch-machine` thin path | |
| Voice of the work | `peram_senior_mlai_engineer` by path | poteto principles for the playbook |

`rules/clt-dual-load.mdc` in the skills repo is the pre-filter for human and agent load.

House HITL wins on secrets, production, irreversible git, CV promote, unknown auth, and money, legal, or health. Reversible edits proceed.

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install intelliarch --trust
# or local:
grok plugin install ./intelliarch --trust
```

Dev symlink:

```bash
mkdir -p ~/.grok/plugins
ln -sfn "$(pwd)/intelliarch" ~/.grok/plugins/intelliarch
```

Also install **pstack** for `/poteto-mode`, and **pstack-map** from this repo. Clone [p10ns11y/skills](https://github.com/p10ns11y/skills) and symlink the skills named in `manifest.json` into the host skill path. Do not copy those files into this plugin.

Rhai is not auto-registered:

```bash
cp intelliarch/.grok/workflows/intelliarch.rhai ~/.grok/workflows/
# or: <repo>/.grok/workflows/
```

## Use

| Surface | How |
|---|---|
| Grok | `/intelliarch <goal>` · `/workflow intelliarch {"goal":"…"}` |
| Cursor | copy `cursor/rules/intelliarch-stack.mdc` into `.cursor/rules/`. Leave `pstack-models.mdc` as `/setup-pstack` wrote it. `/poteto-mode` still runs the playbook. |
| Bot | paste [bot/intelliarch.md](bot/intelliarch.md) as the system card. No webhook. |
| Other hosts | [AGENTS.md](AGENTS.md) plus the skills checkout on that host's skill path. |

On Grok, Bot, and other hosts, model seats are control-graph roles (`fast`, `explore`, `coding`, `deep`, `review`) on the host model. Review uses a fresh context. If pstack is missing, the house row in `pstack-map` `references/map.md` is the playbook.

## Layout

```text
plugin.json
LICENSE
NOTICE.md
README.md
manifest.json
AGENTS.md
commands/intelliarch.md
cursor/commands/intelliarch.md
cursor/rules/intelliarch-stack.mdc
.grok/workflows/intelliarch.rhai
bot/intelliarch.md
agents/intelliarch.md
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
./intelliarch/test/test-thin.sh
```
