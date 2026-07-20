# arch-machine Grok plugin

**Agent-as-TUI** for [arch-machine](https://github.com/p10ns11y/arch-machine): thin-first sentinel, **archy** control plane, consent-gated expand, supervised + FSD rails.

Preferred operator path: **slash commands** + **archy** — not gum `tinfoil tui`.

Host architecture (Eagle + Satellites / offline jobs): see upstream `docs/archy.md` and threads linked from `crates/archy/README.md`.

## Cyclic loop (plugin ↔ archy)

```text
  Grok (+ this plugin)  ──/arch-*──►  arch-machine / archy / scripts
         ▲                                      │
         └──── G / p preloaded grok session ────┘
```

| From | To | How |
|------|-----|-----|
| **Grok** | host | `/arch-status`, `/arch-audit`, `/arch-control`, `/arch-init`, `/arch-expand` |
| **archy** | Grok | NEXT `[p]`, brief Enter, `G` → interactive Grok with ask + context preloaded |

Full how-to: **[docs/CROSS-REF.md](docs/CROSS-REF.md)**.

## Install into Grok

```bash
grok plugin install "$HOME/Work/personal/plugins/arch-machine" --trust
grok plugin enable arch-machine   # if listed but disabled
```

Dev symlink:

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
| `/arch-control` · `--print-root` · `--run` | No (run = TTY) |
| `/arch-init` · `/arch-init --yes` | Yes with `--yes` only |
| `/arch-audit [global\|path\|--dry-run]` | No |
| `/arch-expand <tier> [--yes] [--dry-run]` | Yes with `--yes` only |

## Layout

```text
plugin.json
core-map.json          # thin vs expandable + surfaces.primary=archy
docs/BOUNDARY.md
docs/CROSS-REF.md      # Grok plugin ↔ archy cycle
bin/am-*               # agent-internal helpers (incl. am-archy, am-audit → security-audit.sh)
commands/              # slash commands
skills/arch-machine/   # agent rails
test/
```

## Tests

```bash
./test/test-core-map.sh
./test/test-expand-consent.sh
./test/test-expand-real.sh
./test/test-audit-status.sh
```

## Expand behavior (not a no-op)

With `/arch-expand security --yes`:

1. Ensure arch-machine repo (clone/pull if needed).
2. Run `modules/security/install.sh --agent-expand` when present.
3. Write `.arch-expand-state/security.stamp`.

See `docs/BOUNDARY.md`.
