---
name: control-feeder
description: >-
  Pre-control-graph feeder: rewrite a dumped prompt, pick tools/plugins/skills,
  then route light vs control-graph Outer vs EVA Inner. Use when starting from
  a paste, --prompt-file, --prompt-json, -p/--single, or a messy dump before
  opening a Control Card. Triggers: control-feeder, /control-feeder, dumped
  prompt, rewrite wording, feed the graph, pre-control, prompt feed.
---

# control-feeder

Port copy. Canonical file remains in https://github.com/p10ns11y/skills on master.

> **Load rule:** This file owns **rewrite + route + Feed emit**. Outer phases live in [control-graph](../control-graph/SKILL.md). EVA Inner lives in [eva-emptiness](../../../eva-emptiness/skills/eva-emptiness/SKILL.md). Triage modes live in [agent-orchestrator]. Do **not** paste Card, EVA DAG, or orchestrator checklists here.

```text
// Signature
Feed     : this skill (pre-graph)
Dump     : paste | --prompt-file | --prompt-json | -p/--single | chat dump
Route    ∈ { light, cg-outer, eva-inner }
Light    : agent-orchestrator single_shot | light  — skip Card
CG       : control-graph Outer + Card
EVA      : eva-emptiness Inner only when emptiness gate fires (CG owns Outer)

// Axioms
A1  Rewrite before route — never open Card on the raw dump
A2  One home: route only; do not restate CG/EVA/orchestrator bodies
A3  Harness gap ≠ graph  — permissions / AGENTS.md / MCP / 8192 stay harness
A4  EVA never inlined; never nested grok / grok -p from a live session
A5  Emit a Feed block, then load exactly one next owner
```

Headless `-p` / `--prompt-file` / `--prompt-json` are **ingress only**. This skill is the rewrite-and-route step in front of them.

---

## When to use

| Use | Skip |
|-----|------|
| Dump / paste / headless file before planning | Card already open and phase named |
| Wording is vague (“improve”, “handle”, “look into”) | User gave a one-file obvious fix with verify cmd |
| Need to pick skills + light vs graph vs EVA | Pure mid-graph REPAIR / VERIFY |

---

## Steps

### 1. Ingest

Treat the user text (or file body) as `Dump`. Do not execute tools yet except to read a named `--prompt-file`.

### 2. Rewrite (word choices)

Emit a tighter goal. Rules:

| Drop / replace | Prefer |
|----------------|--------|
| improve, handle, look into, make better, deal with | grep / verify / skip / open Card / implement X |
| “I want you to”, please, just, maybe | imperative one sentence |
| unnamed “the code”, “the system” | path or symbol if present in Dump; else `unknowns[]` |
| stacked goals | one primary goal; rest → non-goals or later gap |
| invented files, cmds, APIs | `unknowns[]` |

Keep: named paths, verify commands, constraints, explicit non-goals.

### 3. Route (first match that holds)

| If | Route | Next owner |
|----|-------|------------|
| Missing capability: perms, `AGENTS.md` rule, MCP `command` missing, output 8192 | note `harness_gap`; continue routing the *work* | harness first, then table below |
| [agent-orchestrator] **single_shot** or **light** | `light` | orchestrator / implement — **no Card** |
| EVA **Use** column: ≥2 of {unknowns dominate; futures disagree at PLAN; auth/irreversible unclear; user asked EVA/blank sheet} **and** no EVA **Skip** | `eva-inner` | load **control-graph** then **eva-emptiness**; Card `inner_mode=eva` |
| CG activate: multi-step · thrash / “until done” · model routing · parallel re-entry | `cg-outer` | load **control-graph**; open Card `inner_mode=standard` |
| else | `light` | orchestrator **light** |

Do not count EVA Skip rows toward the ≥2. Exact EVA fields and Inner DAG: eva-emptiness. Exact Card fields: [control-graph/references/control-card.md](../control-graph/references/control-card.md).

### 4. Pick (names only)

- **skills:** description-trigger matches only — no catalog dump.
- **tools:** built-ins first (`grep`, `read_file`, `search_replace`, `bash`, …). MCP as `server__tool` only if Dump needs a connected server.
- **technique:** `single_shot` | `light` | `cg-outer+standard` | `cg-outer+eva`

### 5. Emit, then hand off

Print the Feed block. Then load **one** next owner. If `cg-outer` or `eva-inner`, copy `goal` / `success` / `verify` / `unknowns` onto a new Card — do not paste the raw Dump.

---

## Feed (emit schema — this skill is SoT)

```markdown
## Feed
| Field | Value |
|-------|--------|
| **goal** | (one rewritten sentence) |
| **dump_source** | paste \| prompt-file \| prompt-json \| -p \| chat |
| **route** | light \| cg-outer \| eva-inner |
| **why** | (one line; cite the row that matched) |
| **technique** | single_shot \| light \| cg-outer+standard \| cg-outer+eva |
| **skills** | name name … |
| **tools** | built-in and/or server__tool … |
| **success** | (observable, if known) |
| **verify** | `cmd` … or unknown |
| **non-goals** | … |
| **unknowns** | … |
| **harness_gap** | none \| permissions \| AGENTS.md \| mcp \| 8192 |
| **next** | implement \| agent-orchestrator \| control-graph \| control-graph+eva-emptiness |
```

---

## Done when

- Feed block printed with rewritten `goal`, `route`, `why`, `next`
- Exactly one next owner named; Card opened only if route is `cg-outer` or `eva-inner`
- No CG/EVA bodies pasted; no nested `grok`

## Do not

- Open a Control Card on the raw dump
- Inline EVA into control-graph or this file
- Treat harness gaps as a reason to start a graph
- Spawn a skill crowd “just in case”
- Run `grok` / `grok -p` from a live session

## Related

Skills: [control-graph](../control-graph/SKILL.md) · [eva-emptiness](../../../eva-emptiness/skills/eva-emptiness/SKILL.md) · [odysseus-navigator](../../../odysseus-navigator/skills/odysseus-navigator/SKILL.md) (judgment after Feed; hooks only) · [agent-orchestrator] · [grok-host-prep]  
Plugin: `eva-emptiness` (Grok marketplace / `../plugins/eva-emptiness`) — Inner only; never paste into this file.

Notes in grok-build `intelli-arch-designs/` (why, not copies):

| Note | Use from this skill |
|------|---------------------|
| `harness-feed-filter.md` | A3: missing capability → harness; graph skills only when emptiness is high |
| `author-vs-inceptor.md` | control-graph + EVA plugin + AGENTS.md are authorship, not a new OS |
| `next-deep-focus.md` | skip EVA on greppable work; do not nest `grok` / add a graph crate |
