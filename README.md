# plugins

Grok Build / agent **marketplace plugins** (installable skill + command + agent + hook packages).

**Location:** `~/Work/personal/plugins` (not `~/plugins`).  
**Catalogs:** `.grok-plugin/marketplace.json`, `.claude-plugin/marketplace.json`, `.cursor-plugin/marketplace.json`

## Install by name

Add this repository once, then install a plugin by its directory name.

Grok Build:

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install <name> --trust
```

`grok plugin marketplace add p10ns11y/plugins` is the same add. The install stops unless you pass `--trust`.

Claude Code:

```text
/plugin marketplace add p10ns11y/plugins
/plugin install <name>@p10ns11y-plugins
```

Open `/plugin`, choose Marketplaces, select `p10ns11y-plugins`, and choose Enable auto-update. Do that once. Auto-update stays off for this marketplace until then.

Cursor:

```bash
agent plugin marketplace add https://github.com/p10ns11y/plugins.git
```

The same command is `cursor-agent plugin marketplace add` when the program is installed under that name. Then run `/plugin`, open Marketplace, and install the plugin.

`scripts/copy-cursor-skills.sh` copies skills into `~/.cursor/skills`.

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
| **eva-emptiness** | Blank-sheet harness: Prior→Probe→Simulate→Score→ActOrAsk + prior agents + C/shell auth tether | `/eva` · `/eva-tether-init` · `/workflow eva-emptiness` |
| **premflow** | Notes/wins/tasks/coach — agent-as-CLI surface | `/note` `/focus` `/journal` |
| **arch-machine** | Thin-first sentinel + consent-gated expand — agent-as-TUI | `/arch-status` `/arch-expand` |
| **mission-map** | Mission briefing: critical path, assigned alignment (`cos`), replan; C PERT/MC + Rust graph | `/mission-map` |
| **uncertainty-laws** | Napkin EV / base rate / ruin / Kelly for foggy finance & life decisions; chains after mission-map | `/uncertainty-laws` |
| **odysseus-navigator** | Judgment plane: Odysseus mistakes, antidotes, spirits; hooks CG/EVA — no tether/Rhai/priors | `/odysseus-core` `/odysseus` |
| **pulse-memory** | Pulse instead of dump: tagged admissions, contradiction resolve, SQLite archive vs memory | `/pulse-memory` · `/workflow pulse-memory` |
| **pstack-map** | Playbook map from Cursor pstack (Lauren Tan, MIT) onto house skills. No fork. | `/pstack-map` |
| **intelli-route** | Route one goal onto at most four skills. pstack or the house row. No vendored bodies. | `/intelli-route` · `/workflow intelli-route` |
| **split-machine** | Place a job on Earth, an entanglement link, a LEO radio handover, a conjunction screen, a GPU, a BQP slice, a typed decision, or prose. Low confidence stops. | `/split-machine` |
| **trust-stack** | Earliest layer for an invariant: shape, check, watch, skill, then a human guide. Does not merge. | `/trust-stack` |
| **steer-log** | Door for a builder brief and a steering doc. No card, no brief. A steering doc may quote only the log. | `/steer-log` |
| **steer-accel** | Five-step loop for a long stretch. Opt-in read watcher while the stretch is on. | `/steer-accel` |
| **concordance** | Corroborate a closed decision. Proceed on a label match at or above tau. Hold returns to the router. | `/concordance` |
| **layout-content-view** | Web layout×content×view stability plus `/lcv-implement` for `data-lcv` marks. Not PNG parity. | `/layout-content-view` `/lcv-implement` |
| **michelin-kitchen** | Seven kitchen habits from Lauren Tan's talk (hosted by Matt Pocock): scripts, findings-first, events over timers, workflow skills. Several include our adaptations. | `/michelin-kitchen <habit>` |
| **craft** | Specifier, coder, cleaner, hardener, QA. CRAP on touched functions; mutation testing on non-Bend code; Bend proofs for pure transitions. [craft/README.md](craft/README.md) | `/craft` |
| **si** | SI workflows that own the write. One profile: data, SI-native review, SI service, deterministic SaaS, infra, or devex. [si/README.md](si/README.md) | `/si` |

---

## eva-emptiness

Blank-sheet / epistemic emptiness. Full scenarios: [eva-emptiness/README.md](eva-emptiness/README.md).

```bash
grok plugin install ./eva-emptiness --trust
# optional: secure C tether (consent) — /eva-tether-init --yes  (or: cd eva-emptiness/c && make)
cp eva-emptiness/.grok/workflows/eva-emptiness.rhai ~/.grok/workflows/   # optional background
```

| Scenario | Use |
|----------|-----|
| No design doc; rumors only; need plan approve | `/eva <goal>` |
| Compile C auth tether (consent) | `/eva-tether-init --yes` |
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


---

## uncertainty-laws

Four napkin probability laws for decisions under uncertainty (EV, base rates, ruin, Kelly). Honest exits include Wait and nothing-now. Chains after **mission-map**.

```bash
grok plugin install uncertainty-laws --trust
# slash: /uncertainty-laws
```

See [uncertainty-laws/README.md](uncertainty-laws/README.md).

## odysseus-navigator

Judgment plane over control-graph + eva-emptiness. Diagnose hubris patterns (Cyclops leak, Sirens rewrite, Helios prod, Circe overbuild, Winds unbounded, Scylla big-bang, ignored prophecy), prescribe antidotes, gate spirits.

```bash
grok plugin install ./odysseus-navigator --trust
# slash: /odysseus-core (one bottleneck) · /odysseus (full Navigator table)
```

See [odysseus-navigator/README.md](odysseus-navigator/README.md).

---

## pstack-map

Playbook map from Cursor [pstack](https://github.com/cursor/plugins/tree/main/pstack) (Lauren Tan, MIT). Does **not** copy pstack. House HITL on irreversible work.

```bash
grok plugin install ./pstack-map --trust
# slash: /pstack-map
# also install pstack itself for /poteto-mode, unslop, how, why
```

See [pstack-map/README.md](pstack-map/README.md) and [pstack-map/NOTICE.md](pstack-map/NOTICE.md).

---

## intelli-route

Routes one goal onto at most four skills. Skill bodies stay in [p10ns11y/skills](https://github.com/p10ns11y/skills), except `eva-emptiness` and the `si` profiles, which load from this repo because the skills-repo entries are sibling symlinks. This plugin does not copy those bodies, and it does not vendor pstack.

```bash
grok plugin install ./intelli-route --trust
# slash: /intelli-route
# optional: cp intelli-route/.grok/workflows/intelli-route.rhai ~/.grok/workflows/
```

See [intelli-route/README.md](intelli-route/README.md) and [intelli-route/NOTICE.md](intelli-route/NOTICE.md).

---

## split-machine

Places one job on the machine that can do it. Earth keeps the processor and the GPUs. Orbit keeps three jobs apart: the entanglement link, a classical LEO radio handover, and a conjunction screen. A closed decision carries a confidence, and low confidence does not branch. intelli-route loads it as a signal.

```bash
grok plugin install ./split-machine --trust
# slash: /split-machine
```

See [split-machine/README.md](split-machine/README.md) and [split-machine/NOTICE.md](split-machine/NOTICE.md).

---

## trust-stack

Places one invariant on the earliest layer that can hold it. The codebase is the agent's memory. A repeated miss is deleted and moved earlier. Landing stays a human act.

```bash
grok plugin install ./trust-stack --trust
# slash: /trust-stack
```

See [trust-stack/README.md](trust-stack/README.md) and [trust-stack/NOTICE.md](trust-stack/NOTICE.md).

---

## concordance

Corroborates one closed decision. The decision model proposes a label. The LLM confirms a label. Proceed on a match at or above the caller's tau. Hold goes back to intelli-route, which does not compute the match.

intelli-route loads this skill when the goal is a closed decision that must be corroborated.

```bash
grok plugin install ./concordance --trust
# slash: /concordance
```

See [concordance/README.md](concordance/README.md) and [concordance/NOTICE.md](concordance/NOTICE.md).

---

## layout-content-view

Routes → Viewports → Orientation → Layouts → Containers → Elements → Interactives. Measures boxes and roles, not pixels. Pilot: devprofile.

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin marketplace update
grok plugin install layout-content-view --trust
# slash: /layout-content-view
```

Until the catalog on the default branch lists this plugin:

```bash
grok plugin install p10ns11y/plugins@feat/layout-content-view#layout-content-view --trust
```

See [layout-content-view/README.md](layout-content-view/README.md).

---

## michelin-kitchen

Seven habits for running agent work like a professional kitchen. Grounded in [Lauren Tan's talk](https://www.youtube.com/watch?v=MN9dGgmLyso), hosted by Matt Pocock. Several skills include our adaptations.

```bash
grok plugin install ./michelin-kitchen --trust
# slash: /michelin-kitchen <habit>
```

See [michelin-kitchen/README.md](michelin-kitchen/README.md).

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

**Alternative:** finish step 2 first, then in Grok run `/premflow:init` (status) and, after
you consent, **`/premflow:init --yes`**. Same end result: `premflow` on `PATH`.

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
| `/premflow:init` | Check CLI on PATH |
| `/premflow:init --yes` | Consent install/upgrade of CLI |
| `/note` `/win` `/task` | Capture via real CLI |
| `/review` | Smart daily review |
| `/coach` | Coach from real ledger data only |
| `/focus` | Pomo in an external TTY (never blocks agent) |
| `/journal` | Ensure journal path; no `$EDITOR` hang |

`bin/pf-*` scripts are **agent-internal** (what Grok runs for those slash commands).
You do not call them from the shell for normal use.

## Eval

This repo uses [NVIDIA SkillEvaluator](https://docs.nvidia.com/skills/skillevaluator/). Source is [NVIDIA/SkillEvaluator](https://github.com/NVIDIA/SkillEvaluator). Latest notes and the verify steps are in [docs/eval/2026-09-08/](docs/eval/2026-09-08/#how-to-verify).
