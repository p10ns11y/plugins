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

> **Load rule:** This file is the **formal SoT** (AppGenMathPhyLang dialect). Expand [references/english-procedure.md](references/english-procedure.md) **only if** a Card field, Pathway, or Score axis is still ambiguous. Expand [references/grok-build-map.md](references/grok-build-map.md) **only if** mapping a step to a Grok Build feature. Outer phases stay in **control-graph** — do **not** paste CG here.  
> **CLT:** DualLoad (A8) — HITL previews short; germane judgment at ActOrAsk; fan-out Probe/Simulate.

```text
// Signature
EVA         : Extra-Vehicular Activity under epistemic emptiness
Skeleton    : Prior → Probe → Simulate → Score → ActOrAsk
Trauma ¬    : overclaim · unbounded ReAct · catastrophic forgetting ·
              auto-approve when unknown = authorization
Progress    : evidence_gain on Card vs pathway assumptions / signposts
Tether      : probe_budget · Claim-via-critical-path · auth hard-stop · signposts
ActOrAsk    : continue | switch | Ask
Pathway     : { short_step, tipping, signpost → switch }   // Simulate stub
Runtime     : control-graph Outer owns transitions
Agents      : EVA Inner (this skill) + prior-* forks

// Axioms
A1  Emptiness gate before EVA Inner — skip if path already clear
A2  Notice IDK on Card before first Probe
A3  One DOE question per Probe round (max ignorance reduction)
A4  Simulate ≥2 prior-diverse Pathways when emptiness_score high
A5  Score ⊥ ImplementerContext (plan + diffs + verify logs only)
A6  Act only via critical_path claims; else Ask (HITL); switch ≠ silent Act
A7  Never cut auth tether (--always-approve / --yolo under EVA = CANCELLED)
A8  Evaluate(δ) ≔ (Correctness, Effectiveness, Efficiency,
                   RobustSatisficing, OptionPreserve)
    // RobustSatisficing = C/E still hold under larger emptiness
    // OptionPreserve    = ≥1 high-value alternate pathway stays live
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
| `evidence_gain` | append only on new disprove/confirm |
| `bias_map` | prior-fork disagreements (after Simulate) |
| `auth_horizon` | none \| hit (HITL required) |
| `disprove_with` | cheapest check that would prove #1 assumption wrong |
| `pathway_active` | live pathway id (optional until Simulate) |
| `signposts[]` | `{id, watch, fires_when → continue\|switch\|Ask}` |

---

## Inner DAG (≤7)

```text
E0 Prior+IDK → E1 one DOE Q → E2 explore probes → E3 Pathways
 → E4 blind Score → E5 ActOrAsk → E6 bounded Act (if continue)
```

| id | done_when | role | on_fail |
|----|-----------|------|---------|
| E0 | Card: knowns/unknowns/priors + `idk` + `disprove_with` | deep | abort_batch |
| E1 | Human answer **or** HOOTL default | human\|fast | escalate_HITL |
| E2 | ≥2 explore summaries **or** probe_budget 0 | explore | continue_siblings |
| E3 | ≥2 Pathways (short_step + tipping + switch signpost) | deep\|coding | escalate_HITL |
| E4 | scores + `bias_map` + trauma_flags + A8 axes | review | abort_batch |
| E5 | continue \| switch \| Ask | human\|deep | escalate_HITL |
| E6 | verify cmds pass; Act cites Probe artifact | coding | continue → REPAIR via CG |

**Prior triad (default = 3):**

| Prior | Bias | Prefer |
|-------|------|--------|
| `prior-conservative` | refuse / delete | missing evidence → don’t ship |
| `prior-generative` | structure from analogy | shape when data≈none |
| `prior-causal` | intervene / disprove | name `disprove_with` |

**Self-bias (once/session):** list assumptions → rank blast radius → Card.`disprove_with` for #1. Cannot name assumptions → Ask.

---

## ActOrAsk

| Choice | When |
|--------|------|
| **continue** | Robust across Pathways; trauma_flags empty; critical_path cited; first step of `pathway_active` |
| **switch** | Signpost fired · tipping hit · fork contradiction → new `pathway_active`; Outer re-ORIENT (not silent Act) |
| **Ask** | Auth horizon · probe_budget 0 ∧ ignorance high · overclaim · switch needs human ack |

---

## Grok / Cursor wiring

| Surface | Load |
|---------|------|
| Cursor / library | this skill (`/eva-emptiness`) |
| Grok plugin | skill + prior agents + tether + `/eva` |
| Background | `/workflow eva-emptiness {"goal":"…"}` after `.rhai` copy to `~/.grok/workflows/` or project `.grok/workflows/` |
| Outer SM | control-graph; EVA owns Inner when gate fires |

Map: [references/grok-build-map.md](references/grok-build-map.md).

### Suggest (name only — do not silent-launch)

| Signal | Suggest |
|--------|---------|
| continue + multi-worker / multi-PR | `/workflow multi-agent-delivery` |
| Probe starved on cold/huge repo | `/workflow context-ignite` |
| Unknowns external/factual | `/deep-research …` |
| Want host-phased EVA | `/workflow eva-emptiness {"goal":"…"}` |
| `auth_horizon=hit` | stay `/eva` / HITL |
| `next=switch` | stay `/eva` or re-Prior with new `pathway_active` |

---

## Done when

- Card: `emptiness_score`, `evidence_gain`, `bias_map`, `disprove_with`, continue \| switch \| Ask reason  
- continue → verify cmds pass; Claim-via-critical-path; OptionPreserve under high emptiness  
- Ask → HITL preview only (approve/amend/abort) — no transcript dump  
- No `--always-approve` / `--yolo`  

## Do not

- Nest this inside `control-graph/SKILL.md`  
- Auto-approve because the model “seems sure”  
- Mega-step “implement everything” before Score  
- Treat third-party “Arena Mode” as SoT — use forks + blind Score  

## Reference

- [english-procedure.md](references/english-procedure.md) — expand only if needed  
- [grok-build-map.md](references/grok-build-map.md) · [permission-tether.md](references/permission-tether.md)  
- Library kernel: skills repo `formal/AppGenMathPhyLang.kernel.md`  
