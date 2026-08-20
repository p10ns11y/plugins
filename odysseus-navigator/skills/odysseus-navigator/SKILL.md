---
name: odysseus-navigator
description: >-
  Engineering-judgment overlay for control-graph + eva-emptiness: diagnose
  Odysseus mistakes (Cyclops leak, Sirens rewrite, Helios prod, Circe overbuild,
  Winds unbounded, Scylla big-bang, ignored prophecy), prescribe professional
  antidotes, and gate Odysseus spirits (Metis, endurance, curiosity, leadership)
  so the ship still reaches Ithaca. Use for architecture/plan review, hubris,
  over-engineering, shiny-tech chase, big-bang cutover, missing observability,
  or when the user says Odysseus / navigator / Ithaca / odysseus-core. Not domain product logic.
---

# odysseus-navigator

> **Load rule:** This file is the **formal SoT** (judgment plane). Expand [references/english-procedure.md](references/english-procedure.md) **only if** a mistake, spirit, or CG/EVA hook is still ambiguous. The English file also holds the copy-paste system prompt.  
> **CLT:** [../rules/clt-dual-load.mdc](../rules/clt-dual-load.mdc) — name the mistake + one next action; do not lecture the myth.

```text
// ── Signature ──────────────────────────────────────────────
ON       : odysseus-navigator (this skill)   // judgment plane
CG       : control-graph                     // control plane (Outer)
EVA      : eva-emptiness                     // epistemic Inner
Ithaca   : true user / business destination  // Card.goal when CG open
Mistake  ∈ { Cyclops, Sirens, Helios, Circe, Winds, Scylla, Prophecy }
Antidote ∈ { Opacity, BoringEvo, SacredProd, YAGNI, Resilience, Incremental, Observability }
Spirit   ∈ { Metis, Endurance, Curiosity, Leadership, Ithaca }
Waters   ∈ { calm, novel-pressure, crisis, R&D, stakeholder }

// ── Axioms (never violate) ─────────────────────────────────
A1  ON ⊨ judgment only;  CG ⊨ Outer;  EVA ⊨ Inner when emptiness fires
    — never inline Outer phases or Prior→Probe→Simulate→Score→ActOrAsk
A2  Diagnose before prescribe — name ≥1 Mistake or explicitly none
A3  Calm waters → Spirit = Ithaca only; humility + measure + YAGNI
A4  ∀ recommendation : ties to Ithaca  (call out drift / empire-building)
A5  Spirit except Ithaca ⇔ Waters match the circumstance table (exact)
A6  Simplest Antidote first; Metis only if novel ∩ under-constrained ∩ high-pressure
A7  Evaluate(δ) ≔ (Correctness, Effectiveness, Efficiency)
A8  Never romanticize cleverness; never encourage hubris
```

**Mission:** Reach Ithaca on time with the ship intact. Keep Odysseus spirits only when the waters truly require them.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| architecture / plan / advisory · hubris · wandering · overbuild · shiny rewrite · big-bang · missing telemetry · “Odysseus”, “Ithaca”, “navigator” | load ON; emit **Navigator** |
| `/odysseus-core` · “nail the core” · faster intelli | one bottleneck, **at most one** Mistake, one `next` — [commands/odysseus-core.md](../../commands/odysseus-core.md) |
| `/odysseus` · several smells | full Navigator table — [commands/odysseus.md](../../commands/odysseus.md) |
| CG ORIENT / PLAN / REVIEW_GATE on multi-step work | diagnose on Card; do not replace Outer |
| EVA Score / ActOrAsk when emptiness high | default Ask if auth/irreversible unclear; no Act-from-hubris |
| ≤2-file obvious fix, mistakes=none | **Skip lecture** → affirm Ithaca + one next step |
| domain autonomy (finder / CV / X) | domain skill owns domain; ON owns **judgment labels only** |

```text
SkillLoad(ORIENT) ≔ description-match ∨ explicit-attach
                  ¬ catalog-dump ¬ myth essay on a typo
```

---

## Diagnose → Prescribe → Judge → Ithaca

```text
1. Name Ithaca (Card.goal if open; else one sentence)
2. Diagnose Mistakes in approach / code / plan / Card  (myth quote ≤1 line)
3. Waters?  calm | novel-pressure | crisis | R&D | stakeholder
4. Prescribe Antidotes → concrete CG hook + EVA hook (no bodies)
5. Spirit: Ithaca always; others iff Waters match
6. Emit Navigator (compact). If mistakes=none: affirm + sharpen next step
```

### Navigator (emit schema — this skill is SoT)

```markdown
## Odysseus
| Field | Value |
|-------|--------|
| **ithaca** | (one sentence destination) |
| **waters** | calm \| novel-pressure \| crisis \| R&D \| stakeholder |
| **mistakes** | none \| Cyclops, Sirens, … |
| **antidotes** | Opacity \| BoringEvo \| … |
| **spirit** | Ithaca [\| Metis \| Endurance \| Curiosity \| Leadership] |
| **why_spirit** | (one line; or “calm → no cleverness”) |
| **cg_hook** | skip \| ORIENT \| PLAN \| HITL_* \| EXECUTE+budget \| VERIFY \| REVIEW_GATE \| dual-run |
| **eva_hook** | skip \| continue \| switch \| Ask |
| **next** | (one concrete action toward Ithaca) |
```

Copy onto the Control Card as optional `odysseus:` only when CG is already open — do not open a Card *because* of a myth label.

---

## Mistake → Antidote → hook

| Mistake | Myth (one line) | You detect | Antidote | CG hook | EVA hook |
|---------|-----------------|------------|----------|---------|----------|
| **Cyclops** | boasting after escape — Polyphemus hears the name | internals, secrets, stack traces, verbose errors, unredacted logs | **Opacity** — security & opacity by default | REVIEW_GATE + HITL on secrets/prod | Ask if auth unknown |
| **Sirens** | song that wrecks the ship for beauty | shiny stack, fashion rewrite, “everyone uses X” | **BoringEvo** — boring tech + evolutionary architecture | PLAN non-goals; surplus ≠ new platform | Probe existing path before switch |
| **Helios** | slaughtering the sacred cattle | prod data/config treated as disposable, no rollback | **SacredProd** — reversible, progressive, canary | HITL_REVIEW; dual-run; no yolo | Ask on irreversible |
| **Circe** | golden cage — years on the island | over-engineering, abstraction palace, YAGNI fail | **YAGNI** — radical simplicity | skip CG if ≤2 files; bound Inner ≤7 | skip EVA on greppable work |
| **Winds** | opened bag; storm scatters the fleet | unbounded concurrency, no back-pressure, no capacity | **Resilience** — limits, circuit breakers, degrade | budgets: `max_*`; independent Inner only | `probe_budget`; no unbounded Probe |
| **Scylla** | forced leap between two deaths | big-bang cutover, false dichotomy | **Incremental** — dual-running, strangler | HITL_PLAN_GATE; INTEGRATE gap-only | switch pathway, don’t leap |
| **Prophecy** | ignoring Tiresias | ship without VERIFY, no feedback, no learning | **Observability** — verify cmds + continuous learning | VERIFY real cmds; REVIEW ⊥ implementer | Score needs evidence; else Ask |

Multiple mistakes allowed. Rank by harm to Ithaca; prescribe the top antidote first.

---

## Spirits (exact circumstance)

| Spirit | Keep iff | Refuse when | Typical hook |
|--------|----------|-------------|--------------|
| **Ithaca** | **always** | — | Card.goal / Navigator.ithaca |
| **Metis** | novel ∩ under-constrained ∩ high-pressure | calm, well-understood, greppable | EVA Probe; CG **explore** / **deep** — not coding-as-architecture |
| **Endurance** | genuine external adversity or crisis recovery | ordinary REPAIR thrash, “keep going” | REPAIR with budget; `no_progress` → HITL not silent grind |
| **Curiosity** | low-cost exploration or deliberate R&D | production, paid-path rewrite, fashion | EVA Probe with budget; CG **explore** readonly |
| **Leadership** | aligning stakeholders / translating technical reality | substituting persuasion for VERIFY | HITL_* with short germane ask |

```text
Waters=calm  ⇒  spirit={Ithaca} only
Spirit\{Ithaca}  ⇏  skip Antidote   // cunning never replaces opacity, budgets, VERIFY
```

---

## Composition (no duplication)

| Concern | Owner | ON does |
|---------|-------|---------|
| Outer phase / budget / HITL | [control-graph](../control-graph/SKILL.md) | name `cg_hook`; never restated phases |
| Inner emptiness DAG | [eva-emptiness](../eva-emptiness/SKILL.md) | name `eva_hook` ∈ {continue, switch, Ask, skip} |
| dump → route | [control-feeder](../control-feeder/SKILL.md) | after Feed, if cg-outer/eva-inner: diagnose at ORIENT |
| material consequence / 2036 | [higher-order-decision-architect](../higher-order-decision-architect/SKILL.md) | labels Sirens/Circe/Scylla; HODA owns the sequence |
| surplus / iron-peak | [architecture-synthesis](../architecture-synthesis/SKILL.md) | Circe vs iron-peak: surplus must serve Ithaca |
| refute-first review | [adversarial-audit](../adversarial-audit/SKILL.md) | Prophecy + Cyclops evidence pack |
| DualLoad | [../rules/clt-dual-load.mdc](../rules/clt-dual-load.mdc) | Navigator is short (extraneous ↓); judgment is germane |
| Grok/Cursor slash harness | [README.md](../../README.md) | `/odysseus-core` fast path; **no** C tether, Rhai, priors, or hooks |

`ON = judgment plane` · `CG = control plane` · `EVA = epistemic Inner` · HODA = material decision sequence.

---

## Anti-patterns

| ¬ | Do |
|---|-----|
| cleverness in calm waters | Ithaca + measure + smallest diff |
| myth essay on a typo | one-line affirm + next step |
| inline CG Outer or EVA DAG | link; emit hooks only |
| Act while auth/irreversible unknown | EVA **Ask**; Helios + Cyclops |
| unbounded “until it works” | Winds → CG budgets / HITL |
| binary rewrite vs freeze | Scylla → dual-run / incremental |
| destination = the architecture itself | name the user/business outcome |
| Metis as excuse to skip VERIFY | Prophecy still fires |
| romanticize wandering | stern, precise, short |

---

## Done when

- [ ] Ithaca named (one sentence)
- [ ] `mistakes` is `none` or a non-empty subset of the enum
- [ ] `waters` + `spirit` judged with a why line
- [ ] `next` is a concrete action (path, cmd, gate, or Ask)
- [ ] No CG/EVA bodies pasted

**Done_when artifact:** Navigator block present in the turn (and on Card iff CG already open).
