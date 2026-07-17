---
description: Start interactive pomodoro in an external terminal (never block agent)
argument-hint: "[plan] [context…]" e.g. 25 ship PR  or  20,4 deep work
---

# /focus — interactive pomo (external TTY only)

Assumes `premflow` is on PATH (system install). If missing → run `/init`.

## Policy (do not violate)

- **Never** run `premflow pomo …` and wait for completion inside the agent tool shell.
- Agent stdin is not a TTY → pause/restart/reset keys will not work there.
- **Always** use the plugin helper (spawns ghostty/alacritty/…) or print a paste-ready command.

## Default action

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
"$PLUGIN/bin/pf-focus" $ARGUMENTS
```

Examples:

```bash
"$PLUGIN/bin/pf-focus" 25 "ship plugin"
"$PLUGIN/bin/pf-focus" 20,4,20,4 "deep work"
"$PLUGIN/bin/pf-focus" --tab 25 "prefer tab if Kitty remote works"
"$PLUGIN/bin/pf-focus" --print-only 25 "context"   # paste-only
"$PLUGIN/bin/pf-focus" --dry-run 25 "x"             # show spawn plan
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
