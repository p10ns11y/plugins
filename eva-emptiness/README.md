# eva-emptiness

Grok Build plugin for **reasoning under epistemic emptiness**.

Skeleton: **Prior → Probe → Simulate → Score → ActOrAsk** (EVA tether).  
When the map is missing: probe budget, Claim-via-critical-path, auth hard-stops. Formal skill body; English only in `skills/eva-emptiness/references/` if needed.

---

## Do not confuse these four surfaces

| Surface | What it is | How you invoke it | Where it lives |
|---------|------------|-------------------|----------------|
| **Skill** | Procedure the model follows | Auto-match / `/eva-emptiness` | `skills/eva-emptiness/` (this plugin) |
| **Plugin** | Installable bundle (skill + `/eva` + agents + hook) | `grok plugin install … --trust` | this directory |
| **`/eva` command** | Interactive plan/ask starter (human on gates) | `/eva <goal>` in TUI | `commands/eva.md` |
| **Workflow `.rhai`** | Host-owned background phases (`agent()` rounds) | `/workflow eva-emptiness {"goal":"…"}` | `.grok/workflows/eva-emptiness.rhai` — **must copy** into `~/.grok/workflows/` or project `.grok/workflows/` |

**Important:** Installing the plugin does **not** register the Rhai workflow. Grok only discovers workflows from project/user `.grok/workflows/*.rhai` (see [config](https://docs.x.ai/build/settings/reference)). Outer control-plane phases stay in the separate **control-graph** skill — never pasted into EVA.

```text
  Interactive (HITL-heavy)     Background (host-scheduled)
  ─────────────────────        ──────────────────────────
  /eva  → skill E0–E6          /workflow eva-emptiness
         permission ask               ↓ /workflows dashboard
         plan mode                    may SUGGEST next:
                                      multi-agent-delivery
                                      context-ignite
                                      /deep-research
```

---

## Install

### 1. Plugin (skill, agents, hook, `/eva`)

```bash
grok plugin install ./eva-emptiness --trust
# marketplace: grok plugin marketplace add https://github.com/p10ns11y/plugins.git
#              grok plugin install eva-emptiness --trust
```

Reload (`r` in `/plugins`). Optional personas:

```bash
mkdir -p ~/.grok/personas
ln -sfn "$(pwd)/eva-emptiness/personas/"*.toml ~/.grok/personas/
```

### 1b. Secure C tether (optional — consent compile)

Hooks **prefer** the C classifier `bin/eva-tether` (bounded stdin, no shell parse of the command).  
If the binary is missing, they use a **portable shell fallback** (zsh preferred when available; bash and other POSIX shells work).

After plugin install, in Grok:

```text
/eva-tether-init          # status only
/eva-tether-init --yes    # consent: compile C11 → bin/eva-tether
```

Manual (same result):

```bash
cd eva-emptiness/c && make    # → ../bin/eva-tether
# or: ../bin/eva-tether-build --yes
```

Needs: C11 compiler (`cc` / `gcc` / `clang`). No network. No sudo.  
Ship tree may already include a prebuilt `bin/eva-tether` for your platform; rebuild with `--force` after source changes.

### 2. Workflow (optional — background EVA)

```bash
cp eva-emptiness/.grok/workflows/eva-emptiness.rhai ~/.grok/workflows/
# or: mkdir -p .grok/workflows && cp … .grok/workflows/
```

```text
/workflow eva-emptiness {"goal":"Your blank-sheet outcome in one sentence"}
```

Watch runs in `/workflows` (pause / resume / stop by display name).

---

## What the plugin contains

| Component | Role |
|-----------|------|
| **Skill** `/eva-emptiness` | Inner DAG + emptiness Card fields |
| **Command** `/eva` | Interactive plan-mode starter |
| **Command** `/eva-tether-init` | Consent-gated compile of C tether |
| **Agents** `prior-conservative` · `prior-generative` · `prior-causal` | Simulate forks → bias map |
| **C tether** `bin/eva-tether` | Secure classifier (prefer) |
| **Hook** Bash PreToolUse | C-first, shell fallback; deny/ask trauma cmds |
| **Personas** (optional) | Same priors as overlays |
| **Workflow** `.grok/workflows/eva-emptiness.rhai` | Background EVA — copy to install |

---

## Solid use cases (when to reach for EVA)

### Use `/eva` (interactive) when…

1. **Greenfield with no design doc** — “Build billing v2 flags” but only three anecdotes exist; you want Q&A + plan approve before edits.
2. **Auth is the real unknown** — agent is ready to ship, but who may mutate prod / push / spend is unclear → Ask, not Act.
3. **Two stakeholders disagree** — product wants speed, security wants refuse; run prior forks and decide from `bias_map`.
4. **You distrust model confidence** — spreadsheet is mostly whitespace; force IDK + one DOE question before any write.

### Use `/workflow eva-emptiness` when…

5. **Same blank-sheet problem, but you want host-phased background work** — kick `/workflow`, keep coding elsewhere; check `/workflows` later.
6. **Repeated emptiness ritual** — same Prior→Score shape every Monday planning; save args.goal and re-launch.

### After EVA, suggest (don’t auto-chain blindly)

| Signal | Suggest |
|--------|---------|
| Act approved + multi-file / multi-worker | `/workflow multi-agent-delivery` |
| Cold / huge repo before Probe | `/workflow context-ignite` |
| Need claim-checked external research | `/deep-research …` |
| Human must approve every gate | stay on `/eva`; do not background |

### Skip EVA when…

- ≤2-file obvious fix with clear verify cmds  
- Mechanical refactor already covered by tests  
- You only need a note/win capture → **premflow**  
- You only need host archy sentinel → **arch-machine**

---

## EVA suggests workflows (skill behavior)

When the skill or `/eva` finishes Score/ActOrAsk, it should **name** a next workflow (not silently launch):

```text
Suggest: /workflow multi-agent-delivery {"goal":"…"}   # if Act + multi-worker
Suggest: /workflow context-ignite                      # if Probe starved on repo map
Suggest: /deep-research …                              # if unknowns are factual/external
Stay on /eva                                           # if auth_horizon=hit
```

---

## Cursor (no Grok plugin / no Rhai engine)

Cursor cannot `grok plugin install` or run `/workflow *.rhai`. Use the **equivalents**:

| Grok | Cursor equivalent |
|------|-------------------|
| Plugin skill | `~/.cursor/skills/eva-emptiness` → skills lib symlink |
| `/eva` | `~/.cursor/commands/eva.md` → type `/eva` in Agent chat |
| `/workflow eva-emptiness` | `~/.cursor/commands/eva-workflow.md` → `/eva-workflow` (phased Agent stand-in) |
| C/shell tether hook | `~/.cursor/hooks/eva-tether-shell.sh` on `beforeShellExecution` (C `bin/eva-tether` preferred) |
| Discovery | `~/.cursor/rules/eva-emptiness.mdc` (agent-requestable) |

Quick install (user-global) from this repo:

```bash
# from plugins checkout
PLUGIN="$(pwd)/eva-emptiness"

ln -sfn "$PLUGIN/skills/eva-emptiness" ~/.cursor/skills/eva-emptiness
# optional discovery rule (if you keep rules next to skills):
# ln -sfn ~/Work/personal/skills/rules/eva-emptiness.mdc ~/.cursor/rules/eva-emptiness.mdc

mkdir -p ~/.cursor/commands ~/.cursor/hooks
cp "$PLUGIN/cursor/commands/eva.md" ~/.cursor/commands/eva.md
cp "$PLUGIN/cursor/commands/eva-workflow.md" ~/.cursor/commands/eva-workflow.md
# Prefer symlink so the hook can find bin/eva-tether + shell.inc
ln -sfn "$PLUGIN/cursor/hooks/eva-tether-shell.sh" ~/.cursor/hooks/eva-tether-shell.sh
# Optional: compile C tether (same binary Grok uses)
( cd "$PLUGIN/c" && make )
# Wire beforeShellExecution → eva-tether-shell.sh in ~/.cursor/hooks.json
```

Canonical Cursor assets live under `eva-emptiness/cursor/` (commands + shell tether). Grok keeps `commands/eva.md` + `bin/eva-tether-pretool.sh` (C-first).

Then in Cursor Agent: `/eva <goal>` or `/eva-workflow <goal>`. Reload if slash menu is stale (new chat / restart).

## Trust

Hooks run with your privileges. Review `hooks/hooks.json`, `bin/eva-tether-pretool.sh`, `c/`, and `bin/eva-tether` (if present) before `--trust`.
Cursor: review `cursor/hooks/eva-tether-shell.sh` + your `~/.cursor/hooks.json`.  
Compile only after consent (`/eva-tether-init --yes`).