---
description: Check or install the premflow CLI (consent-gated clone + build + user-local install)
argument-hint: "[--status] | [--yes] [--force]"
---

# /init — premflow CLI install (with consent)

**User-facing surface:** `/init`, `/init --yes`, `/init --yes --force`.  
Do not tell the user to run `pf-init` in a shell — that binary is agent-internal.

The plugin assumes the `premflow` CLI is already on **PATH**. This command
checks status and, only with **explicit user consent**, downloads and installs
the CLI from the public repo.

**Repo:** https://github.com/thecuriousts/premflow  
**Install prefix (default):** `~/.local/bin` (no sudo)  
**Soon:** package install will replace clone/build; this flow stays consent-first.

## Policy (do not violate)

1. **Never** clone, build, or write under `~/.local` without the user agreeing.
2. Status checks are always safe (read-only).
3. If the user has **not** consented, explain what will happen and **ask** first.
4. No personal machine paths. System PATH only.
5. Talk to the user in **slash-command** terms (`/init --yes`), not `pf-init`.

## Step 1 — Status (always run first)

Agent-internal implementation (do not print this as the user instruction):

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
"$PLUGIN/bin/pf-init" --status
```

- If premflow is on PATH → report path and stop (unless user asked to reinstall).
- If missing → go to Step 2.

## Step 2 — Consent

Tell the user clearly:

- Source: `https://github.com/thecuriousts/premflow`
- Actions: clone → build → install into `~/.local` (no sudo)
- Needs: `git`, `cmake`, C11 compiler, `make`; network for first clone
- PATH: `~/.local/bin` must be on PATH after install

**Ask:** *May I download and install premflow now?*  
Only after a clear **yes**, or if `$ARGUMENTS` already contains `--yes` from
the user running `/init --yes`, proceed.

## Step 3 — Install (consent given)

Agent-internal (maps from `/init --yes` / `/init --yes --force`):

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
"$PLUGIN/bin/pf-init" --yes $ARGUMENTS
```

| User runs | Agent runs |
|-----------|------------|
| `/init` | `pf-init --status` |
| `/init --yes` | `pf-init --yes` |
| `/init --yes --force` | `pf-init --yes --force` |

## Step 4 — Verify

```bash
command -v premflow && premflow
```

If the binary is under `~/.local/bin` but not found, tell the user to add:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

to their shell config, then reload Grok.

## Manual install (user prefers DIY)

```bash
git clone https://github.com/thecuriousts/premflow.git
cd premflow
./build.sh
make install   # → ~/.local/bin/premflow
```

Requires **CMake 3.14+** and a C11 compiler. See the [premflow README](https://github.com/thecuriousts/premflow).
