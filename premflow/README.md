# premflow — Grok plugin

Full plugin: free-form **skill** + slash commands + helpers for the two hard cases.

| Path | Role |
|------|------|
| In-session | `/note` `/win` `/task` `/review` → real `premflow` CLI |
| **Coach** | `/coach` → pull review/tasks/journal, Grok helps (no invented facts) |
| External TTY | `/focus` → `bin/pf-focus` spawns interactive pomo |
| Agent-safe file | `/journal` → `journal --ensure` or `bin/pf-journal` |

## Install (discover)

```bash
mkdir -p ~/.grok/plugins ~/.grok/skills
ln -sfn ~/Work/personal/plugins/premflow ~/.grok/plugins/premflow
ln -sfn ~/Work/personal/plugins/premflow/skills/premflow ~/.grok/skills/premflow
```

Or: `grok plugin install ~/Work/personal/plugins/premflow --trust`

Reload Grok / Plugins tab `r`.

Optional: `export PREMFLOW_TERMINAL=ghostty` (or alacritty).

## Requires

- Built/installed `premflow` on PATH or `~/Work/personal/premflow/build/premflow`
- For focus spawn: ghostty, alacritty, kitty, … (else paste-ready command)

## Pomo

Interactive countdown **must** live in a real terminal window. The agent only launches or prints the command.

## Journal

`premflow journal --ensure` creates the same template as the classic journal command but **prints the path** and does not open an editor — safe for agents.
