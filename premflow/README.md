# premflow — Grok plugin

Skill + slash commands + helpers. Grok runs the **premflow** CLI for capture and
review; interactive pomo and full `$EDITOR` journal stay outside the agent shell.

| Slash / path | Role |
|--------------|------|
| `/init` | Status or (with consent) install the CLI |
| `/note` `/win` `/task` `/review` | In-session CLI |
| `/coach` | Review + tasks + journal → coach (no invented facts) |
| `/focus` | `bin/pf-focus` → interactive pomo in a real TTY |
| `/journal` | `bin/pf-journal` / `journal --ensure` (path only) |

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

If either fails, the plugin commands will fail until the CLI is fixed.

**Optional later:** a package install will replace clone/build; until then use
manual install or `/init` (step 3).

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

### Step 3 — If the CLI is still missing: `/init`

Only needed when step 1 was skipped or `premflow` is not on `PATH`.

1. In Grok, run **`/init`** (status only — safe).
2. Agent explains clone → build → `~/.local` install and **asks for consent**.
3. After you say yes (or pass `--yes`), it runs `bin/pf-init --yes`:
   - clone/update → `~/.cache/premflow/src`
   - `./build.sh`
   - `make install` → `~/.local/bin/premflow`
4. Confirm again: `command -v premflow`.

Never installs without consent. `--force` rebuilds even if already on `PATH`.

### Step 4 — Optional environment

```bash
# tests / packaging override (absolute path to binary)
export PREMFLOW_BIN=/path/to/premflow

# preferred terminal for /focus spawn (else auto: ghostty, alacritty, kitty, …)
export PREMFLOW_TERMINAL=ghostty

# force tab vs window strategy for pf-focus
export PREMFLOW_FOCUS_SURFACE=auto   # or tab | window
```

---

## Runtime policies

### Pomo

Interactive countdown **must** run in a real terminal (TTY keys: space/p, r, R, q).
The agent must **not** wait on `premflow pomo` in the tool shell — only
`bin/pf-focus` (spawn or print-only).

### Journal

- `premflow journal` alone opens `$EDITOR` and **blocks** — avoid in-agent.
- Default: `premflow journal --ensure` or `bin/pf-journal` → create template,
  **print absolute path**, no editor wait.
- `bin/pf-journal --open` spawns editor in an external terminal (non-blocking).

---

## Helpers

| Script | Role |
|--------|------|
| `bin/pf-resolve` | Resolve `premflow` from `PATH` or `PREMFLOW_BIN`; exit 1 + hint if missing |
| `bin/pf-init` | `--status` / `--yes` / `--force` CLI install |
| `bin/pf-focus` | External TTY pomo |
| `bin/pf-journal` | Agent-safe journal ensure (+ optional external editor) |
