---
name: arch-machine
description: >-
  Operator surface for arch-machine: thin-first sentinel status, consent-gated
  thin install, threat-focused audit, expand/pull modules or profiles, archy
  control plane. Prefer archy + slash commands over gum tinfoil TUI. Use when
  user mentions arch-machine, archy, tinfoil, sentinel install, expand
  security/ml profile, thin bootstrap, or host audit.
---

# arch-machine — agent-as-TUI (archy-first)

**Mission:** Drive **arch-machine** through Grok slash commands. Keep install **thin** by default; pull expandable tiers only with **`--yes`**. Prefer **`archy`** (Ratatui control plane) over **`tinfoil tui`** (gum legacy).

**User surface = slash commands.** `bin/am-*` are agent-internal — never tell the user to run `am-init` in a shell.

## Cyclic: Grok plugin ↔ archy

```text
Grok (this skill/plugin) ── /arch-* ──► arch-machine backends / archy
         ▲                                    │
         └──── archy G/p preload launch ──────┘
```

| Direction | Operator action |
|-----------|-----------------|
| Stay in Grok | `/arch-status`, `/arch-audit`, `/arch-control`, `/arch-init`, `/arch-expand` |
| Leave archy for Grok | In archy: job → NEXT `[p]` / brief Enter / `G` (preloaded prompt) |

Detail: `$PLUGIN/docs/CROSS-REF.md` · host `docs/archy.md` section “Grok plugin”.

## Architecture (host repo)

When the arch-machine checkout is present:

- **archy** = Eagle + Satellites + TEA (`crates/archy`, `docs/archy.md`)
- **Audit** = `maintenance/security-audit.sh` (malware · ports · supply · config)
- **Grok Explain** = interactive preload via archy (not bare empty Build)
- Skill in repo: `.agents/skills/eagle-satellite-elomaxz`

Design threads: Eagle+Satellites / offline jobs — see host `crates/archy/README.md`.

## Resolve plugin + map

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
MAP="$PLUGIN/core-map.json"
```

## Immutable rails

1. **Fail closed** without consent: expand/init/install require `/… --yes` after clear operator agreement.
2. **FSD / unsupervised** may auto-run only: status, version, audit, map, path-probe, archy-print-root (`core-map.json` → `modes.fsd.allowlist`).
3. **Never** auto-install `ml-dev` or `security-dev` full profiles.
4. Prefer **`archy`** + **`security-audit.sh`** / CLI over **`tinfoil tui`**.
5. Confirm real command output; do not invent machine state.
6. Speak **slash commands** to the user (`/arch-init --yes`), not `am-*`.

## Command map

| Intent | User surface | Agent runs |
|--------|--------------|------------|
| Status / PATH | `/arch-status` | `$PLUGIN/bin/am-status` |
| Core map | `/arch-status map` | `am-map` |
| Control plane | `/arch-control` · `--run` | `am-archy` |
| Thin init | `/arch-init` · `/arch-init --yes` | `am-init` |
| Audit | `/arch-audit [global\|path\|--dry-run]` | `am-audit` → security-audit.sh |
| Expand | `/arch-expand security` then `--yes` | `am-expand …` |

## Supervised vs FSD

| Mode | Behavior |
|------|----------|
| Supervised (default) | Always status first; ask before mutate |
| FSD | Auto status/audit only; any expand/init without `--yes` → refuse |

## Core vs expandable

See `$PLUGIN/docs/BOUNDARY.md` and `$PLUGIN/core-map.json`. Thin core = sentinel + archy source/runtime; modules/profiles are expandable.

## Remote pull + expand (real work)

Cache default: `~/.cache/arch-machine/src` from `p10ns11y/arch-machine` (`sentinel`). Only with `/arch-init --yes` or expand with consent.

`/arch-expand <module> --yes` is **not** a no-op:

1. Ensure repo (clone/pull if needed; prefers `ARCH_MACHINE_ROOT` → `~/arch-machine` over system install).
2. Run `modules/<name>/install.sh --agent-expand` when present.
3. Write `.arch-expand-state/<name>.stamp`.

Full `ml-dev` / `security-dev` still require explicit profile name + `--yes` (never auto).
