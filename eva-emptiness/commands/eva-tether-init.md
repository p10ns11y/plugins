---
description: Check or compile the secure C EVA tether (consent-gated; shell fallback always works)
argument-hint: "[--status] | [--yes] [--force] [--prefix DIR]"
---

# /eva-tether-init — compile EVA C tether (with consent)

**User-facing surface:** `/eva-tether-init`, `/eva-tether-init --yes`, `/eva-tether-init --yes --force`.  
Do not tell the user to run `eva-tether-build` in a shell — that script is agent-internal.

Hooks prefer the **C binary** `bin/eva-tether` for secure classification. If the
binary is missing or the host has no C compiler, hooks use a **portable shell
fallback** (zsh preferred when available; bash and other POSIX shells work).

## Policy (do not violate)

1. **Never** compile or write `bin/eva-tether` without the user agreeing.
2. Status checks are always safe (read-only).
3. If the user has **not** consented, explain what will happen and **ask** first.
4. No network. No sudo. Sources stay inside the plugin tree.
5. Talk to the user in **slash-command** terms (`/eva-tether-init --yes`), not the internal script name.

## Step 1 — Status (always run first)

Agent-internal implementation (do not print this as the user instruction):

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
"$PLUGIN/bin/eva-tether-build" --status
```

- If `bin/eva-tether` is executable → report path and stop (unless reinstall).
- If missing → go to Step 2.

## Step 2 — Consent

Tell the user clearly:

- Source: plugin `c/eva_tether.c` + `c/main.c` (C11, no dependencies)
- Actions: compile → write `bin/eva-tether` (kept next to hooks)
- Needs: C11 compiler (`cc` / `gcc` / `clang`); `make` optional
- Without C: hooks keep working via shell fallback
- Optional: `--prefix ~/.local` also copies to `~/.local/bin/eva-tether`

**Ask:** *May I compile the EVA tether C binary now?*  
Only after a clear **yes**, or if `$ARGUMENTS` already contains `--yes` from
the user running `/eva-tether-init --yes`, proceed.

## Step 3 — Build (consent given)

Agent-internal (maps from `/eva-tether-init --yes` / `--force`):

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
"$PLUGIN/bin/eva-tether-build" --yes $ARGUMENTS
```

| User runs | Agent runs |
|-----------|------------|
| `/eva-tether-init` | `eva-tether-build --status` |
| `/eva-tether-init --yes` | `eva-tether-build --yes` |
| `/eva-tether-init --yes --force` | `eva-tether-build --yes --force` |

## Step 4 — Verify

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?}"
test -x "$PLUGIN/bin/eva-tether"
printf '%s' '{"toolInput":"git push origin main"}' | "$PLUGIN/bin/eva-tether" --mode=grok
# expect: decision deny JSON
printf '%s' 'echo hi' | "$PLUGIN/bin/eva-tether" --mode=grok
# expect: empty (allow)
```

## Manual build (user prefers DIY)

```bash
cd path/to/eva-emptiness/c
make
# → ../bin/eva-tether
```
