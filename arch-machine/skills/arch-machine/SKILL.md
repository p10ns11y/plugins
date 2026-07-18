---
name: arch-machine
description: >-
  Operator surface for arch-machine: thin-first sentinel status, consent-gated
  thin install, read-only audit, expand/pull modules or profiles. Prefer agent
  slash commands over tinfoil gum TUI. Use when user mentions arch-machine,
  tinfoil, sentinel install, expand security/ml profile, or thin bootstrap.
---

# arch-machine — agent-as-TUI (not gum tinfoil)

**Mission:** Drive **arch-machine** through Grok slash commands. Keep install **thin** by default; pull expandable tiers only with **`--yes`**. Do **not** default to `tinfoil tui`.

**User surface = slash commands.** `bin/am-*` are agent-internal — never tell the user to run `am-init` in a shell.

## Resolve plugin + map

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
MAP="$PLUGIN/core-map.json"
```

## Immutable rails

1. **Fail closed** without consent: expand/init/install require `/… --yes` after clear operator agreement.
2. **FSD / unsupervised** may auto-run only: status, version, audit, map, path-probe (`core-map.json` → `modes.fsd.allowlist`).
3. **Never** auto-install `ml-dev` or `security-dev` full profiles.
4. Prefer **`tinfoil audit`** / CLI over **`tinfoil tui`**.
5. Confirm real command output; do not invent machine state.
6. Speak **slash commands** to the user (`/arch-init --yes`), not `am-*`.

## Command map

| Intent | User surface | Agent runs |
|--------|--------------|------------|
| Status / PATH | `/arch-status` | `$PLUGIN/bin/am-status` |
| Core map | `/arch-status map` or `$PLUGIN/bin/am-map` | `am-map` |
| Thin init | `/arch-init` · `/arch-init --yes` | `am-init --status` / `am-init --yes` |
| Audit | `/arch-audit [path]` | `am-audit` → `tinfoil audit` |
| Expand | `/arch-expand security` then `--yes` | `am-expand …` |

## Supervised vs FSD

| Mode | Behavior |
|------|----------|
| Supervised (default) | Always status first; ask before mutate |
| FSD | Auto status/audit only; any expand/init without `--yes` → refuse |

## Core vs expandable

See `$PLUGIN/docs/BOUNDARY.md` and `$PLUGIN/core-map.json`. Thin core = sentinel `tinfoil` + `install.sh --thin`. Modules/profiles are expandable.

## Remote pull + expand (real work)

Cache default: `~/.cache/arch-machine/src` from `p10ns11y/arch-machine` (`sentinel`). Only with `/arch-init --yes` or expand with consent.

`/arch-expand <module> --yes` is **not** a no-op:

1. Ensure repo (clone/pull if needed; prefers `ARCH_MACHINE_ROOT` → `~/arch-machine` over system install).
2. Run `modules/<name>/install.sh --agent-expand` when present (security: keeper check + `.agent-expanded`).
3. Write `.arch-expand-state/<name>.stamp`.

Full `ml-dev` / `security-dev` still require explicit profile name + `--yes` (never auto).
