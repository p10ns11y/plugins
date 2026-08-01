# plugins

Grok Build / agent **marketplace plugins** (installable skill + command + agent + hook packages).

**Location:** `~/Work/personal/plugins` (not `~/plugins`).  
**Catalog:** `.grok-plugin/marketplace.json`

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
# or local: grok plugin marketplace add ~/Work/personal/plugins
grok plugin install eva-emptiness --trust
```

---

## Layers (avoid confusion)

| Layer | Repo / path | Job | Invoke |
|-------|-------------|-----|--------|
| **Plugin** | this repo (`premflow/`, `eva-emptiness/`, …) | Bundle for `/plugins` + marketplace | `grok plugin install <name> --trust` |
| **Skill** | inside plugin `skills/` (often symlinked from [skills](https://github.com/p10ns11y/skills) library) | Procedure text agents load | auto-match or `/skill-name` |
| **Slash command** | plugin `commands/*.md` | Thin TUI entry | `/eva`, `/note`, … |
| **Workflow `.rhai`** | `~/.grok/workflows/` or project `.grok/workflows/` | Host-owned background `agent()` phases | `/workflow <meta.name>` · dashboard `/workflows` |
| **Portable skill library** | [p10ns11y/skills](https://github.com/p10ns11y/skills) | Cursor + shared procedures; workflow *docs* + some `.rhai` | symlink skills; **copy** `.rhai` into Grok workflows dirs |

**Plugins do not auto-register Rhai.** If a plugin ships `.grok/workflows/*.rhai` (eva-emptiness, arch-machine), you still **copy** (or symlink) into a discovery root. Official discovery: project `<repo-root>/.grok/workflows/`, user `~/.grok/workflows/` ([Grok config](https://docs.x.ai/build)).

```text
skills library ──symlink──► plugin skills/     (procedure SoT for Cursor + Grok)
plugin install  ──trust───► agents, hooks, /commands
.rhai file      ──cp/ln───► ~/.grok/workflows/  (background engine)
```

---

## Plugin catalog

| Plugin | Role | Typical invoke |
|--------|------|----------------|
| **eva-emptiness** | Blank-sheet harness: Prior→Probe→Simulate→Score→ActOrAsk + prior agents + Bash tether | `/eva` · `/workflow eva-emptiness` |
| **premflow** | Notes/wins/tasks/coach — agent-as-CLI surface | `/note` `/focus` `/journal` |
| **arch-machine** | Thin-first sentinel + consent-gated expand — agent-as-TUI | `/arch-status` `/arch-expand` |

---

## eva-emptiness

Blank-sheet / epistemic emptiness. Full scenarios: [eva-emptiness/README.md](eva-emptiness/README.md).

```bash
grok plugin install ./eva-emptiness --trust
cp eva-emptiness/.grok/workflows/eva-emptiness.rhai ~/.grok/workflows/   # optional background
```

| Scenario | Use |
|----------|-----|
| No design doc; rumors only; need plan approve | `/eva <goal>` |
| Same problem, run phases in background | `/workflow eva-emptiness {"goal":"…"}` |
| After Act, multi-worker delivery | suggest `/workflow multi-agent-delivery` |
| Obvious bugfix | skip EVA |

---

## arch-machine

```bash
grok plugin install ./arch-machine --trust
# slash: /arch-status · /arch-init · /arch-audit · /arch-expand
# optional: copy arch-machine/.grok/workflows/*.rhai → ~/.grok/workflows/
```

See [arch-machine/README.md](arch-machine/README.md) and `arch-machine/docs/BOUNDARY.md`.

---

## premflow

Grok skill + slash commands for notes, wins, tasks, review, coaching, external
pomo, and agent-safe journal. The plugin drives the **premflow** CLI; it does
not ship the binary.

| | |
|--|--|
| **Plugin** (this repo) | `premflow/` — skill, slash commands, agent helpers |
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

**Alternative:** finish step 2 first, then in Grok run `/init` (status) and, after
you consent, **`/init --yes`**. Same end result: `premflow` on `PATH`.

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

### 3. Use (slash commands only)

| Command | What it does |
|---------|----------------|
| `/init` | Check CLI on PATH |
| `/init --yes` | Consent install/upgrade of CLI |
| `/note` `/win` `/task` | Capture via real CLI |
| `/review` | Smart daily review |
| `/coach` | Coach from real ledger data only |
| `/focus` | Pomo in an external TTY (never blocks agent) |
| `/journal` | Ensure journal path; no `$EDITOR` hang |

`bin/pf-*` scripts are **agent-internal** (what Grok runs for those slash commands).
You do not call them from the shell for normal use.
