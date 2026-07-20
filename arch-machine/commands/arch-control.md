---
description: Locate or launch archy control plane (primary UI)
argument-hint: "[--print-root] | [--run]"
---

# /arch-control — archy (main TUI)

**User surface:** `/arch-control` · `/arch-control --print-root` · `/arch-control --run`

**archy** is the main operator surface for arch-machine (Ratatui, Eagle + Satellites TEA). Prefer this over `tinfoil tui` (gum legacy).

## Policy

- Default **probe only** (locate binary + repo) — FSD-safe.
- `--run` starts interactive TUI (needs a real terminal; not for headless FSD).
- Build if missing: `cargo build --release --manifest-path crates/archy/Cargo.toml` in the repo.

## Agent

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?}"
"$PLUGIN/bin/am-archy" $ARGUMENTS
```

| User | Result |
|------|--------|
| `/arch-control` | Show archy path + how to build |
| `/arch-control --print-root` | Print resolved arch-machine root |
| `/arch-control --run` | `exec archy` with `TINFOIL_ROOT` set |

Docs in repo: `docs/archy.md`. Skill: `eagle-satellite-elomaxz` (in arch-machine).
