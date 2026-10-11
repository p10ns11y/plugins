# aihero-map

Alignment **map** from [AI Hero](https://www.aihero.dev/skills.md) by **Matt Pocock**.

Agents fetch that markdown once, then one skill page with `.md` on the end. The HTML page is the same article for a browser. This plugin names the house skill. It does **not** ingest those skills. `claude plugins install mattpocock-skills` is Claude Code only.

```text
  /aihero-map     alignment name → house skill
  /intelli-route  at most four loads
  /pstack-map     playbook map (Lauren Tan)
```

## How the three stacks meet

This marketplace is the control plane. [pstack](https://github.com/cursor/plugins/tree/main/pstack), by Lauren Tan, is the execution playbook once the work has a name. [AI Hero](https://www.aihero.dev/skills.md), by Matt Pocock, is the alignment chain for one product repo, from a shared understanding through a spec, tickets, a build, a review, and a lookback. They meet in `intelli-route`: at most four loads, the pstack body when it is installed, otherwise the house row. A product repo runs [setup](https://www.aihero.dev/skills-setup-matt-pocock-skills.md) once before any leave-upstream skill. This map does not.

A stretch runs in that order. Fog stays `eva-emptiness`. A closed decision is a `steer-log` card. The path is `mission-map`. The router picks the loads. The build is pstack or `craft`. A break on the same harness reads `steer-accel`. A lookback is `trust-stack`. The pull request uses the house shape.

On an overlap, load the row with the stronger claim. That is the better chance the check already exists here. It is not a calibrated probability. The table is [references/map.md](skills/aihero-map/references/map.md).

## Right way, by harness

Read [skills.md](https://www.aihero.dev/skills.md). That is the agent index. The HTML page at `/skills` is the same article for a browser. A skill article is `https://www.aihero.dev/skills-<name>.md`. The hashed section links inside the index 404, so do not follow them.

[mattpocock/skills](https://github.com/mattpocock/skills) says to pick one install per agent. A plugin plus `npx skills add` installs every skill twice.

| Harness | Install | Where the files land | Updates |
|---------|---------|----------------------|---------|
| Claude Code | `claude plugin install mattpocock-skills@claude-plugins-official` | the Claude plugin, read-only | by itself |
| Cursor | `npx skills@latest add mattpocock/skills -a cursor` | `.agents/skills/` in the repo, or `~/.cursor/skills/` with `-g` | `npx skills@latest update` |
| Grok | `npx skills@latest add mattpocock/skills -a grok` | `.grok/skills/` in the repo, or `~/.grok/skills/` with `-g` | `npx skills@latest update` |

When the installer asks which skills to take, include `setup-matt-pocock-skills`. Then run `/setup-matt-pocock-skills` once in that repo. It writes `docs/agents/` and an `## Agent skills` block. If `CLAUDE.md` already exists it writes that file. Grok and Cursor keep `AGENTS.md` as the file they read.

You type a user-invoked skill (`/grill-me`, `/wayfinder`, `/to-spec`). The agent may reach a model-invoked skill when the task fits (`tdd`, `domain-modeling`, `pr`). A user-invoked skill may call a model-invoked skill. It does not call another user-invoked skill.

On an overlap with this map, use the house skill and do not install that upstream name. Leave-upstream names (triage, wizard, teach, wait-what, a throwaway prototype) are the ones worth installing.

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install aihero-map --trust
# or local:
grok plugin install ./aihero-map --trust
```

Dev symlink:

```bash
mkdir -p ~/.grok/plugins
ln -sfn "$(pwd)/aihero-map" ~/.grok/plugins/aihero-map
```

Slash: `/aihero-map`.

## Layout

```text
skills/aihero-map/   # map SoT
commands/            # /aihero-map
agents/
```

Credit: Matt Pocock. Neighbor playbooks: Lauren Tan, via `pstack-map`.
