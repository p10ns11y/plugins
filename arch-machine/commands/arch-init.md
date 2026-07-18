---
description: Check or thin-install arch-machine sentinel (consent-gated)
argument-hint: "[--status] | [--yes] [--force] [--dry-run]"
---

# /arch-init — thin sentinel install

**User surface:** `/arch-init`, `/arch-init --yes`, `/arch-init --yes --force`  
Do not tell the user to run `am-init` in a shell.

## Policy

1. **Never** clone or run `install.sh` without consent (`--yes`).
2. Status checks are always safe.
3. Default install is **thin** (`--thin`) — not ml-dev/security-dev.
4. Talk in slash terms (`/arch-init --yes`).

## Step 1 — Status

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?}"
"$PLUGIN/bin/am-init" --status
```

## Step 2 — Consent

If thin tools missing, explain:

- Clone/cache: `~/.cache/arch-machine/src` from `github.com/p10ns11y/arch-machine`
- Run: `./install.sh --thin` (may need sudo for `/usr/local/bin`)
- Optional dry-run: `/arch-init --yes --dry-run`

**Ask** unless `$ARGUMENTS` already contains `--yes`.

## Step 3 — Install

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?}"
"$PLUGIN/bin/am-init" $ARGUMENTS
```

| User | Agent |
|------|--------|
| `/arch-init` | `am-init --status` |
| `/arch-init --yes` | `am-init --yes` |
| `/arch-init --yes --dry-run` | `am-init --yes --dry-run` |
| `/arch-init --yes --force` | `am-init --yes --force` |
