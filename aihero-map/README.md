# aihero-map

Alignment **map** from [AI Hero](https://www.aihero.dev/skills) by **Matt Pocock**.

The bodies stay upstream. This plugin names the house skill. It does **not** ingest those skills.

```text
  /aihero-map     alignment name → house skill
  /intelli-route  at most four loads
  /pstack-map     playbook map (Lauren Tan)
```

## How the three stacks meet

This marketplace is the control plane. [pstack](https://github.com/cursor/plugins/tree/main/pstack), by Lauren Tan, is the execution playbook once the work has a name. [AI Hero](https://www.aihero.dev/skills), by Matt Pocock, is the alignment chain for one product repo, from a shared understanding through a spec, tickets, a build, a review, and a lookback. They meet in `intelli-route`: at most four loads, the pstack body when it is installed, otherwise the house row.

A stretch runs in that order. Fog stays `eva-emptiness`. A closed decision is a `steer-log` card. The path is `mission-map`. The router picks the loads. The build is pstack or `craft`. A break on the same harness reads `steer-accel`. A lookback is `trust-stack`. The pull request uses the house shape.

On an overlap, load the row with the stronger claim. That is the better chance the check already exists here. It is not a calibrated probability. The table is [references/map.md](skills/aihero-map/references/map.md).

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
