# eva-emptiness

Grok Build plugin for **reasoning under epistemic emptiness**.

Skeleton: **Prior → Probe → Simulate → Score → ActOrAsk** (EVA tether).  
Jump into the void when the map is missing — stay clipped to probe budget, Claim-via-critical-path, and auth hard-stops. Flashy certainty is free; wisdom costs one good question.

## Why a plugin (not only a skill)

| Component | What you get |
|-----------|----------------|
| **Skill** `/eva-emptiness` | Inner DAG + emptiness Card fields |
| **Command** `/eva` | Plan-mode starter that runs the skeleton |
| **Agents** `prior-conservative` · `prior-generative` · `prior-causal` | Prior-diverse Simulate forks → bias map |
| **Hook** Bash PreToolUse tether | Denies push/yolo/reset-hard style trauma |
| **Personas** (optional copy) | Same priors as subagent overlays |

Ships as one `grok plugin install` — marketplace-ready shape (skills + commands + agents + hooks).

## Install

From a clone of [plugins](https://github.com/p10ns11y/plugins) (or this monorepo path):

```bash
grok plugin install ./eva-emptiness --trust
# or: grok plugin marketplace add <your-plugins-repo> && grok plugin install eva-emptiness --trust
```

Reload plugins (`r` in `/plugins`). Optional personas:

```bash
mkdir -p ~/.grok/personas
ln -sfn "$(pwd)/eva-emptiness/personas/"*.toml ~/.grok/personas/
```

Cursor / portable library: symlink the skill dir (already done if you use the skills library install).

## Use

```text
/eva <blank-sheet goal>
```

Or attach/load skill `eva-emptiness` and follow E0–E6. Pair with `control-graph` for Outer phases — do not paste CG into this skill.

## Sellable pitch (one line)

**Process architecture for blank sheets** — turns Grok’s plan mode, explore children, worktree forks, and permission surface into an EVA harness that surfaces model/harness bias via prior disagreement instead of automating anxiety.

## Trust

Hooks run with your privileges. Review `hooks/hooks.json` + `bin/eva-tether-pretool.sh` before `--trust`.
