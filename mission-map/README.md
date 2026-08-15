# mission-map

Grok / Cursor plugin: a **Mission: Impossible briefing**, not a future oracle.

- **Skill** — what / how / when, calculated risk, replan when the outside world hits
- **C (`c/`)** — PERT expected time, bounded Monte Carlo on a simple path, \(d t_e / d m\)
- **Rust (`rust/`)** — DAG, longest path (critical path), JSON map

## Install

From the [plugins](https://github.com/p10ns11y/plugins) marketplace:

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install mission-map --trust
```

Dev symlink:

```bash
ln -sfn "$HOME/Work/personal/plugins/mission-map" "$HOME/.grok/plugins/mission-map"
ln -sfn "$HOME/Work/personal/plugins/mission-map/skills/mission-map" "$HOME/.grok/skills/mission-map"
ln -sfn "$HOME/Work/personal/plugins/mission-map/skills/mission-map" "$HOME/.cursor/skills/mission-map"
```

## Build / test

```bash
make -C c test
cd rust && cargo test && cargo run -- ../examples/sample-map.json
```

## Invoke

- Slash: `/mission-map`
- Skill auto-match: “mission map”, “calculated risk”, “replan”

Personal live maps stay off this repo (e.g. `~/.grok/mission-maps/`).
