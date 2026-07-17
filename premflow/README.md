# premflow — Grok plugin

Skill + slash commands. Grok runs the **premflow** CLI for capture and review;
interactive pomo and full `$EDITOR` journal stay outside the agent shell.

## What you run (slash commands)

| Command | Role |
|---------|------|
| `/init` | Check whether the CLI is on PATH (safe) |
| `/init --yes` | After you consent: download, build, install CLI |
| `/init --yes --force` | Rebuild/reinstall even if already present |
| `/note` `/win` `/task` | Capture via real CLI |
| `/review` | Smart daily review |
| `/coach` | Review + tasks + journal → coach (no invented facts) |
| `/focus` | Interactive pomo in a real TTY (never blocks the agent) |
| `/journal` | Ensure journal path; no `$EDITOR` hang |
| `/journal --open` | Ensure path, then open editor in an external terminal |

You do **not** need to call `pf-*` scripts yourself. Those are agent-internal
helpers the slash commands use under the hood.

---

## Setup (ordered)

### Step 1 — Install the premflow CLI

This plugin **does not** ship the C binary. Source of truth:

**https://github.com/thecuriousts/premflow**

**Prerequisites:** CMake 3.14+, C11 compiler (`cc` / `gcc` / `clang`), `git`, `make`.

**Manual install (user-local, no sudo):**

```bash
git clone https://github.com/thecuriousts/premflow.git
cd premflow
./build.sh
make install
# installs: ~/.local/bin/premflow
```

**PATH** — ensure the install dir is visible:

```bash
export PATH="$HOME/.local/bin:$PATH"
# add the same line to your shell rc if needed
```

**Verify:**

```bash
command -v premflow   # must print a path
premflow              # prints help
```

If either fails, slash commands that need the CLI will fail until this is fixed.

**Optional later:** a package install will replace clone/build. Until then use
manual install (this step) or `/init --yes` after the plugin is installed (step 3).

### Step 2 — Install this Grok plugin

Pick one.

**A. Grok CLI** (from a checkout of the `plugins` repo, or any path to this folder):

```bash
grok plugin install /path/to/plugins/premflow --trust
```

**B. Symlink:**

```bash
mkdir -p ~/.grok/plugins ~/.grok/skills
ln -sfn /path/to/plugins/premflow ~/.grok/plugins/premflow
# optional: also expose the skill outside the plugin tree
ln -sfn /path/to/plugins/premflow/skills/premflow ~/.grok/skills/premflow
```

Reload Grok, or in the Plugins tab press `r`.

### Step 3 — If the CLI is still missing

1. In Grok, run **`/init`** (status only — safe).
2. The agent explains clone → build → `~/.local` install and **asks for consent**.
3. Approve, then run **`/init --yes`** (or answer yes when asked).
4. Confirm: `command -v premflow`.

Use **`/init --yes --force`** only to rebuild/reinstall on purpose.

### Step 4 — Optional environment

```bash
# tests / packaging override (absolute path to binary)
export PREMFLOW_BIN=/path/to/premflow

# preferred terminal for /focus spawn (else auto: ghostty, alacritty, kitty, …)
export PREMFLOW_TERMINAL=ghostty

# force tab vs window strategy for /focus
export PREMFLOW_FOCUS_SURFACE=auto   # or tab | window
```

---

## Runtime policies

### Pomo

Interactive countdown **must** run in a real terminal (TTY keys: space/p, r, R, q).
Use **`/focus`** — never wait on `premflow pomo` inside the agent tool shell.

### Journal

- `premflow journal` alone opens `$EDITOR` and **blocks** — avoid in-agent.
- Default **`/journal`**: create template, **print absolute path**, no editor wait.
- **`/journal --open`**: open editor in an external terminal (non-blocking).

---

## Agent internals (Grok Build only)

Slash command implementations invoke helpers under `bin/`. Operators and end
users should stick to `/…` commands above.

| Script | Used by | Role |
|--------|---------|------|
| `bin/pf-resolve` | other helpers | Resolve `premflow` from `PATH` or `PREMFLOW_BIN` |
| `bin/pf-init` | `/init` | Status / consent install of CLI |
| `bin/pf-focus` | `/focus` | External TTY pomo |
| `bin/pf-journal` | `/journal` | Agent-safe journal ensure (+ optional external editor) |
