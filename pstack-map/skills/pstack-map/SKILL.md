---
name: pstack-map
description: >-
  Playbook map from Cursor pstack (Lauren Tan / poteto, MIT): match a playbook,
  load installed pstack when present, else house skills. House HITL wins on
  secrets, prod, irreversible git, unknown auth. Use for /pstack-map,
  pstack, poteto-mode, rigor playbooks, or when the user asks to use pstack
  without forking it. Not a pstack copy. Not control-graph Outer.
---

# pstack-map

> **Load rule:** This file is the **map SoT**. Expand [references/map.md](references/map.md) only to pick a playbook or fallback. Do **not** paste pstack playbook bodies, principle files, or control-graph / EVA rituals here.

```text
// Signature
PM       : pstack-map (this skill)     // map plane
Pstack   : Lauren Tan pstack (MIT)        // SoT if installed
CG       : control-graph                  // Outer
EVA      : eva-emptiness                  // Inner when emptiness fires
ON       : odysseus-navigator             // judgment

// Axioms
A1  Map; do not copy. pstack bodies stay upstream.
A2  House HITL ⊨ irreversible  (secrets, prod, shared push, CV, auth unknown)
    — overrides pstack "never-block-on-the-human" on those rows only
A3  Cursor-only → skip or name fallback (Graphite land, benny Slack,
    sol/fable Task models, cursor-team-kit deslop)
A4  One home: CG Outer, EVA Inner, ON judgment, orchestrator workers
A5  Credit Lauren Tan / pstack MIT on every emit
```

**Mission:** Use pstack rigor on Grok without a second copy of pstack.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| `/pstack-map` · “use pstack” · poteto-mode · rigor playbook | load PM; emit **Map** |
| pstack already installed and playbook fits | load that pstack skill **after** the map; do not rewrite it |
| ≤2-file obvious fix | **Skip** map lecture; one next step |
| user asked to fork/vendor pstack | refuse copy; point at NOTICE.md |

```text
SkillLoad ≔ description-match ∨ /pstack-map
          ¬ catalog-dump ¬ paste playbook.md
```

---

## Vendor verdict (this repo)

| Move into this repo | Keep upstream | Skip on Grok |
|---------------------|---------------|--------------|
| this map + HITL override | 21 principles, 22 playbooks, unslop, how, why, architect, arena, swarm, … | Graphite merge-when-ready, benny, overnight yolo land, automate-me, make-bot-ui |

Worth copying later only if: (1) pstack is **not** installable on the host, **and** (2) one leaf has no house owner. Then copy **one** file, keep Lauren Tan copyright, SHA in NOTICE. Default: **do not copy**.

---

## Steps

1. Match one playbook (table below; full rows in [map.md](references/map.md)).
2. If pstack installed: load the named pstack skill or `/poteto-mode`. Else use **house**.
3. Set `hitl`: `required` iff secrets / prod / irreversible git / CV / auth unknown.
4. Name `cg_hook` / `eva_hook`. Do not inline Outer or EVA Inner.
5. Emit Map. Credit line required.

### Playbook → house (short)

| Playbook | House if pstack missing |
|----------|-------------------------|
| investigation | `how` / `why` / structured-repo-explore |
| bug-fix, tdd | reproduce → fix → VERIFY cmds |
| feature, refactoring | CG Inner ≤7; smallest diff |
| prototype | throwaway; no production path |
| architect | architecture-synthesis; not coding-as-plan |
| arena / swarm | concurrent-cli-agents; parent owns VERIFY |
| interrogate | review + adversarial-audit |
| babysit | pr-babysit |
| shipping | tidy-commit-push; **no** auto-push |
| autonomous / orchestrate / autopilot-* | CG budgets; HITL on land |
| authoring a skill | portable-skill-author + skill-design-principles |
| session pickup / pause | agent-orchestrator resume (gap only) |
| worktree cleanup | git-worktrees |
| unslop / technical-writing | unslop if installed; else short formal English |

---

## Overrides (house wins)

| pstack | Here |
|--------|------|
| never-block-on-the-human | proceed on reversible work; **pause** on A2 rows |
| Graphite land / merge-when-ready | verify; wait for human push |
| `poteto-agent` | `explore` / `coding` / `review`; use poteto-agent only if pstack installed |
| sol / fable / opus roles | CG `fast` `coding` `deep` `review`; host default model |
| `/loop` until morning | CG `max_loop_iters`; stop on `no_progress`×2 |

---

## Map (emit schema — this skill is SoT)

```markdown
## Pstack-map
| Field | Value |
|-------|--------|
| **playbook** | (one name or skip) |
| **pstack** | installed: skill-or-mode \| missing |
| **house** | (owner skill names) |
| **cg_hook** | skip \| ORIENT \| PLAN \| HITL_* \| EXECUTE+budget \| VERIFY \| REVIEW_GATE |
| **eva_hook** | skip \| continue \| switch \| Ask |
| **hitl** | none \| required (reason) |
| **credit** | Lauren Tan / pstack MIT · https://github.com/cursor/plugins/tree/main/pstack |
| **next** | (one action) |
```

---

## Composition

| Concern | Owner | PM does |
|---------|-------|---------|
| Outer / budgets / HITL shape | control-graph | `cg_hook` only |
| Inner emptiness | eva-emptiness | `eva_hook` only |
| hubris / overbuild | odysseus-navigator | optional after Map |
| dump rewrite | control-feeder | after Feed, map playbook |
| workers / worktrees | agent-orchestrator · git-worktrees | name, do not restate |
| pstack playbooks / principles | installed **pstack** | load; never paste |

---

## Anti-patterns

| ¬ | Do |
|---|-----|
| vendor pstack into this plugin | map + NOTICE |
| paste playbook.md into the turn | load the skill |
| silent Graphite / yolo land | HITL |
| second control plane | hooks only |
| drop credit | emit `credit` row |

---

## Done when

- [ ] One playbook named or `skip`
- [ ] `pstack` is `installed` or `missing` (honest)
- [ ] `credit` row present
- [ ] No pstack file copied; no CG/EVA bodies pasted
- [ ] `hitl=required` on A2 rows

**Done_when artifact:** Map block in the turn.
