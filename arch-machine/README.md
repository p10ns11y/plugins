# arch-machine Grok plugin

**Agent-as-TUI** for [arch-machine](https://github.com/p10ns11y/arch-machine): thin-first sentinel, consent-gated expand, supervised + FSD rails. Preferred operator surface over `tinfoil tui` (gum).

## Install into Grok

Preferred (trust + enable like premflow):

```bash
grok plugin install "$HOME/Work/personal/plugins/arch-machine" --trust
grok plugin enable arch-machine   # if listed but disabled
```

Dev symlink (discover path only; still enable in `~/.grok/config.toml` `[plugins].enabled`):

```bash
mkdir -p "$HOME/.grok/plugins"
ln -sfn "$HOME/Work/personal/plugins/arch-machine" "$HOME/.grok/plugins/arch-machine"
grok plugin validate "$HOME/Work/personal/plugins/arch-machine"
```

Confirm `arch-machine` appears under `grok plugin list` and in `[plugins].enabled`.

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
./test/test-expand-real.sh   # honest --yes expand on fixtures/mock-arch
```

## Expand behavior (not a no-op)

With `/arch-expand security --yes`:

1. Ensure arch-machine repo (clone/pull if needed).
2. Run `modules/security/install.sh --agent-expand` (real prep + `.agent-expanded`).
3. Write `.arch-expand-state/security.stamp`.

See `docs/BOUNDARY.md`.
