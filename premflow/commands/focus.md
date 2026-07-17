---
description: Start interactive pomodoro in an external terminal (never block agent)
argument-hint: "[plan] [context…]" e.g. 25 ship PR  or  20,4 deep work
---

# /focus — interactive pomo (external TTY only)

Assumes `premflow` is on PATH. If missing → tell user to run `/init` (then `/init --yes` with consent).

## Policy (do not violate)

- **Never** run `premflow pomo …` and wait for completion inside the agent tool shell.
- Agent stdin is not a TTY → pause/restart/reset keys will not work there.
- **Always** spawn via the agent helper below, or print a paste-ready command.
- User-facing examples use **`/focus …`**. The `pf-focus` path is agent-internal only.

## User examples

```text
/focus 25 ship plugin
/focus 20,4,20,4 deep work
/focus --tab 25 prefer tab if Kitty remote works
/focus --print-only 25 context
```

## Agent action

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
"$PLUGIN/bin/pf-focus" $ARGUMENTS
```

### Tab vs window

| Preference | How |
|------------|-----|
| **True tab + command** | Kitty with remote control (`kitty @ launch --type=tab`) — use `--tab` or `PREMFLOW_FOCUS_SURFACE=tab` |
| **Ghostty (this machine)** | D-Bus `new-window-command` → **same app, new window** (Ghostty has `new-tab` but **not** tab+command via D-Bus) |
| Fallback | New emulator process window; or paste after `Ctrl+Shift+T` |

**TTY keys:** space/p pause · r restart segment · R reset plan · q quit.

### Later (stretch): focus-complete signal

Not implemented yet. Direction: when plan ends, `notify-send` / desktop notification / optional hook file so Grok can notice — without blocking the agent during the timer.
