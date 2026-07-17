# plugins

Grok Build / agent plugins (installable skill + command packages).

## premflow

Grok skill + slash commands for notes, wins, tasks, review, coaching, external
pomo, and agent-safe journal. The plugin drives the **premflow** CLI; it does
not ship the binary.

| | |
|--|--|
| **Plugin** (this repo) | `premflow/` — skill, `/commands`, `bin/` helpers |
| **CLI** (separate) | [github.com/thecuriousts/premflow](https://github.com/thecuriousts/premflow) — must be on `PATH` |
| **Docs** | [premflow/README.md](premflow/README.md) |

### 1. Install the CLI

Needs: CMake 3.14+, C11 compiler, `git`, `make`. Installs to `~/.local/bin` (no sudo).

```bash
git clone https://github.com/thecuriousts/premflow.git
cd premflow
./build.sh
make install
```

Put `~/.local/bin` on `PATH` if it is not already:

```bash
export PATH="$HOME/.local/bin:$PATH"
# persist in your shell config, then open a new shell
```

Check:

```bash
command -v premflow && premflow
```

**Alternative:** install this plugin first (step 2), then in Grok run `/init` and
approve the download/build. Same end result: `premflow` on `PATH`.

### 2. Install this plugin

From a clone of **this** repo (`plugins`):

```bash
grok plugin install ./premflow --trust
```

Or symlink:

```bash
mkdir -p ~/.grok/plugins
ln -sfn "$(pwd)/premflow" ~/.grok/plugins/premflow
```

Reload Grok (or Plugins tab → `r`).

### 3. Use

| Command | What it does |
|---------|----------------|
| `/init` | Check CLI; with consent, install/upgrade CLI |
| `/note` `/win` `/task` | Capture via real CLI |
| `/review` | Smart daily review |
| `/coach` | Coach from real ledger data only |
| `/focus` | Pomo in an external TTY (never blocks agent) |
| `/journal` | Ensure journal path; no `$EDITOR` hang |
