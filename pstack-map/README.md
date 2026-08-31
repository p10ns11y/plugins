# pstack-map

Playbook **map** from [Cursor pstack](https://github.com/cursor/plugins/tree/main/pstack) by **Lauren Tan** (poteto). MIT.

pstack stays the source of truth. This plugin does **not** copy playbooks, principles, or agents.

```text
  /pstack-map     match playbook → load pstack or house fallback
  /poteto-mode       pstack itself (install separately)
```

## Vendor check

| Copy into this repo? | Why |
|----------------------|-----|
| **No** — 21 principles, 22 playbooks, unslop/how/why, poteto-mode | Already installable; informal first-person; Cursor Graphite/sol/fable; would drift |
| **No** — benny, automate-me, make-bot-ui | Cursor/Slack/personal |
| **Yes** — this map, HITL override, NOTICE | Grok house style (formal, short); credits; A2 HITL vs “never block” |

Copy a pstack file later only if the host cannot install pstack **and** no house owner exists. Keep Lauren Tan copyright and a git SHA in `NOTICE.md`.

## Credits

- **Lauren Tan** — pstack. https://github.com/cursor/plugins/tree/main/pstack
- License: MIT, Copyright (c) 2026 Lauren Tan — full text in [NOTICE.md](NOTICE.md)
- This map: p10ns11y, MIT ([LICENSE](LICENSE))

## Install

Install **pstack** (Cursor `/add-plugin pstack`, or the Grok marketplace copy). Then:

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install pstack-map --trust
# or local:
grok plugin install ./pstack-map --trust
```

Dev symlink:

```bash
mkdir -p ~/.grok/plugins
ln -sfn "$(pwd)/pstack-map" ~/.grok/plugins/pstack-map
```

Cursor: copy `cursor/commands/*.md` into the project or user commands dir.

## Tests

```bash
./test/test-thin.sh
```

## Layout

```text
plugin.json
LICENSE                 # this plugin (p10ns11y)
NOTICE.md               # Lauren Tan / pstack MIT
commands/               # Grok slash
cursor/commands/
agents/
skills/pstack-map/   # map SoT
  SKILL.md
  references/map.md
test/test-thin.sh
```
