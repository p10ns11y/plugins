# premflow — Grok plugin

Full plugin: free-form **skill** + slash commands + helpers for the two hard cases.

| Path | Role |
|------|------|
| **Init** | `/init` → check or (with consent) install the `premflow` CLI |
| In-session | `/note` `/win` `/task` `/review` → real `premflow` CLI |
| **Coach** | `/coach` → pull review/tasks/journal, Grok helps (no invented facts) |
| External TTY | `/focus` → `bin/pf-focus` spawns interactive pomo |
| Agent-safe file | `/journal` → `journal --ensure` or `bin/pf-journal` |

## Requires: premflow CLI on PATH

This plugin does **not** ship the C binary. Install [premflow](https://github.com/thecuriousts/premflow) system-wide (user-local is fine):

```bash
git clone https://github.com/thecuriousts/premflow.git
cd premflow
./build.sh
make install   # → ~/.local/bin/premflow (no sudo)
```

Ensure `~/.local/bin` is on your `PATH`. Requires **CMake 3.14+** and a C11 compiler.

**Via plugin (consent-gated):** after the plugin is installed, run `/init` — status by default; with your yes, `bin/pf-init --yes` clones under `~/.cache/premflow/src`, builds, and installs to `~/.local`. A proper package install will replace clone/build later; consent stays required.

Optional override for tests: `export PREMFLOW_BIN=/path/to/premflow`.

Optional terminal: `export PREMFLOW_TERMINAL=ghostty` (or alacritty, kitty, …).

## Install this plugin

```bash
# from a clone of this plugins repo, or a path to the premflow plugin directory
grok plugin install /path/to/plugins/premflow --trust
```

Or link into Grok’s plugin dir (adjust source path to where you keep the plugin):

```bash
mkdir -p ~/.grok/plugins ~/.grok/skills
ln -sfn /path/to/plugins/premflow ~/.grok/plugins/premflow
# optional dual skill discovery:
ln -sfn /path/to/plugins/premflow/skills/premflow ~/.grok/skills/premflow
```

Reload Grok / Plugins tab `r`.

## Pomo

Interactive countdown **must** live in a real terminal window. The agent only launches or prints the command.

## Journal

`premflow journal --ensure` creates the same template as the classic journal command but **prints the path** and does not open an editor — safe for agents.

## Helpers

| Script | Role |
|--------|------|
| `bin/pf-resolve` | Locate `premflow` on PATH (or `PREMFLOW_BIN`) |
| `bin/pf-init` | Status / consent install of CLI |
| `bin/pf-focus` | External TTY pomo |
| `bin/pf-journal` | Agent-safe journal ensure (+ optional external editor) |
