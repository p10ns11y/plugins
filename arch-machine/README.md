# arch-machine Grok plugin

**Agent-as-TUI** for [arch-machine](https://github.com/p10ns11y/arch-machine): thin-first sentinel, consent-gated expand, supervised + FSD rails. Preferred operator surface over `tinfoil tui` (gum).

## Install into Grok

```bash
ln -sfn "$HOME/Work/personal/plugins/arch-machine" "$HOME/.grok/plugins/arch-machine"
grok plugin validate "$HOME/Work/personal/plugins/arch-machine"
grok plugin list
```

Or: `grok plugin install /path/to/Work/personal/plugins/arch-machine`

## Slash commands

| Command | Mutates? |
|---------|----------|
| `/arch-status` · `/arch-status map` | No |
| `/arch-init` · `/arch-init --yes` | Yes with `--yes` only |
| `/arch-audit [path]` | No |
| `/arch-expand <tier> [--yes] [--dry-run]` | Yes with `--yes` only |

## Layout

```text
plugin.json
core-map.json          # machine-readable thin vs expandable
docs/BOUNDARY.md
bin/am-*               # agent-internal helpers
commands/              # slash commands
skills/arch-machine/   # agent rails
test/                  # unit + consent tests
```

## Tests

```bash
./test/test-core-map.sh
./test/test-expand-consent.sh
```
