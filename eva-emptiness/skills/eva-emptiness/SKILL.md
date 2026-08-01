---
name: eva-emptiness
description: >-
  Reasoning under epistemic emptiness: Prior → Probe → Simulate → Score →
  ActOrAsk (EVA tether). Use when the map/data is missing, unknowns dominate,
  requirements are rumor-thin, or authorization is the real unknown — not when
  the fix path is already clear. Composes with control-graph Outer; Grok Build
  plugin adds prior-agents + tether hooks. Triggers: eva-emptiness, /eva-emptiness,
  epistemic emptiness, blank sheet, EVA, Prior Probe Simulate Score ActOrAsk,
  trauma-shaped answers, robust decision making under uncertainty.
---

# eva-emptiness

> **Load rule:** This file is SoT for the EVA Inner skeleton. Expand [references/grok-build-map.md](references/grok-build-map.md) **only if** mapping a step to a Grok Build feature. Outer phases/budgets stay in **control-graph** — do **not** paste CG here.  
> **CLT:** DualLoad (A8) — keep HITL previews structured; preserve germane judgment at ActOrAsk; fan-out Probe/Simulate.

```text
// Signature
EVA         : Extra-Vehicular Activity under epistemic emptiness
Skeleton    : Prior → Probe → Simulate → Score → ActOrAsk
Trauma ¬    : overclaim · unbounded ReAct · catastrophic forgetting ·
              auto-approve when unknown = authorization
Progress    : evidence_gain on Card (not “still working”)
Tether      : probe_budget · Claim-via-critical-path · auth hard-stop

// Axioms
A1  Emptiness gate before EVA Inner — skip if path already clear
A2  Notice IDK on Card before first Probe
A3  One DOE question per Probe round (max ignorance reduction)
A4  Simulate ≥2 prior-diverse forks before Act when emptiness_score high
A5  Score ⊥ ImplementerContext (plan + diffs + verify logs only)
A6  Act only via critical_path claims; else Ask (HITL)
A7  Never cut auth tether (--always-approve / --yolo under EVA = CANCELLED)
A8  Evaluate(δ) ≔ (Correctness, Effectiveness, Efficiency)
```

Related skills (load by name): `control-graph` · `concurrent-cli-agents` · `adversarial-audit` · `higher-order-decision-architect`.

---

## Use / skip

| Use | Skip |
|-----|------|
| Unknowns dominate knowns; thin/no gold data | ≤2-file obvious fix |
| Multiple futures disagree at PLAN | Clear acceptance + known verify cmds |
| Auth / irreversibility unclear | Pure mechanical refactor with tests |
| User asks EVA / epistemic emptiness / blank sheet | |

---

## Emptiness gate (ORIENT)

Trigger EVA Inner when ≥2 hold; write on Card:

| Field | Meaning |
|-------|---------|
| `emptiness_score` | low \| med \| high |
| `knowns[]` / `unknowns[]` | explicit split |
| `idk` | ≥1 honest “I don’t know” |
| `probe_budget` | default 3 cheap probes |
| `evidence_gain` | list; append only on new falsify/confirm |
| `bias_map` | prior-fork disagreements (after Simulate) |
| `auth_horizon` | none \| hit (HITL required) |

---

## Inner DAG (≤7)

```text
E0 Prior+IDK → E1 one DOE Q → E2 explore probes → E3 prior forks
 → E4 blind Score → E5 ActOrAsk → E6 bounded Act (if Act)
```

| id | done_when | role | on_fail |
|----|-----------|------|---------|
| E0 | Card has knowns/unknowns/priors + `idk` | deep | abort_batch |
| E1 | Human answer **or** recorded HOOTL default | human\|fast | escalate_HITL |
| E2 | ≥2 explore summaries **or** probe_budget 0 | explore | continue_siblings |
| E3 | ≥2 prior-diverse fork returns (default triad) | deep\|coding | escalate_HITL |
| E4 | scores + `bias_map` + trauma_flags | review | abort_batch |
| E5 | Act plan approved **or** HITL Ask | human\|deep | escalate_HITL |
| E6 | verify cmds pass; every Act step cites Probe artifact | coding | continue → REPAIR via CG |

**Prior triad (default fork count = 3):**

| Prior | Bias | Prefer |
|-------|------|--------|
| `prior-conservative` | refuse / delete | missing evidence → don’t ship |
| `prior-generative` | structure from analogy | fluid abstraction when data≈none |
| `prior-causal` | intervene / falsify | Pearl do-operator; name killing experiment |

**Self-bias probe (once per emptiness session):** list assumptions treated as facts; rank blast radius; propose cheapest probe that kills #1. If model cannot name assumptions → Ask, do not Act.

---

## ActOrAsk

| Act | Ask (HITL) |
|-----|------------|
| Robust across forks; trauma_flags empty; critical_path cited | Auth event horizon · fork contradiction · probe_budget 0 with ignorance high · overclaim |

Best answers under no data: **robust + humble**. Flashy certainty is free; wisdom costs one good question.

---

## Grok / Cursor wiring

| Surface | Load |
|---------|------|
| Cursor / library | this skill (`/eva-emptiness` when skill-linked) |
| Grok plugin | skill + prior agents + tether hooks + `/eva` |
| Background workflow | `/workflow eva-emptiness {"goal":"…"}` after copying `.rhai` into `~/.grok/workflows/` or project `.grok/workflows/` (plugin install alone is not enough) |
| Outer SM | `control-graph` owns phases; EVA owns Inner when gate fires |

Feature→step map: [references/grok-build-map.md](references/grok-build-map.md).

### Suggest workflows (do not silent-launch)

After Score / ActOrAsk, **name** a next step for the human:

| Signal | Suggest |
|--------|---------|
| Act + multi-worker / multi-PR | `/workflow multi-agent-delivery` |
| Probe starved on cold/huge repo | `/workflow context-ignite` |
| Unknowns are external/factual | `/deep-research …` |
| Want host-phased EVA, not chat | `/workflow eva-emptiness {"goal":"…"}` |
| `auth_horizon=hit` | stay interactive (`/eva` / HITL) — no background mutate |

---

## Done when

- Card updated: `emptiness_score`, `evidence_gain`, `bias_map`, Act **or** Ask reason  
- If Act: verify cmds run; Claim-via-critical-path holds  
- If Ask: structured HITL preview only (approve/amend/abort) — no transcript dump  
- No `--always-approve` / `--yolo` used under EVA  

## Do not

- Nest this procedure inside `control-graph/SKILL.md` (token bloat on every CG load)  
- Auto-approve tools because the model “seems sure”  
- Mega-step “implement everything” before Score  
- Treat third-party “Arena Mode” as SoT — use forks + blind Score (official worktrees/subagents)  
