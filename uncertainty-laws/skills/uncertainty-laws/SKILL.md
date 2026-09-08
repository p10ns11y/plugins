---
name: uncertainty-laws
version: 0.1.0
description: >
  Break fog under uncertainty with four napkin probability laws (expected value,
  base rates, variance/ruin, Kelly). Use for /uncertainty-laws, wealth/finance
  confusion, “should I refinance / sell / wait”, risky life forks, or when
  arithmetic looks smart but the path can still ruin you. Honest exits include
  Wait, Park, and “nothing you can do now.” Links to mission-map for path vs size.
metadata:
  author: p10ns11y <9104920+p10ns11y@users.noreply.github.com>
  tags:
    - probability
    - expected-value
    - kelly
    - finance
    - wealth
    - decision
    - uncertainty
---

# uncertainty-laws

> **Load rule:** This file owns the **decision napkin**. Mission topology stays in `mission-map`. Emptiness (no map) stays in `eva-emptiness`. Do not invent Swedish law, medical advice, or market forecasts. Do not dump PII or live claim amounts.

```text
// Signature
UL       : uncertainty-laws (this skill)   // napkin plane
MM       : mission-map                     // path / Do-Risk-Wait-Park
EVA      : eva-emptiness                   // when priors are blank
ON       : odysseus-navigator              // hubris patterns

// Axioms
A1  Run laws in order: EV → base rate → ruin → Kelly. Never Kelly first.
A2  You are one path, not the average of a thousand copies of you.
A3  Survival is the strategy. A path that can hit zero has long-run value ~0.
A4  Being right is not being paid. Mispricing is the product.
A5  Honest exit beats fake clarity: Wait / Park / nothing-now are valid.
A6  House HITL on irreversible money, legal, or health acts.
```

**Mission:** Turn fog into one honest next act — or an honest “none yet.”

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| Wealth / debt / refinance / sell / insurance fog | Activate |
| “Should I bet / apply / commit / escalate?” | Activate |
| Average returns, win rates, “sure thing” evidence | Activate |
| One file + known verify command | Skip |
| Pure scheduling of an already-chosen Do | Prefer mission-map |

Slash: `/uncertainty-laws`. Also match “four laws”, “expected value”, “Kelly”, “base rate”, “ruin”, “honest uncertainty”.

---

## The four laws (order is the product)

| # | Law | Napkin question | Fail looks like |
|---|-----|-----------------|-----------------|
| 1 | **Expected value** | Is the *price* wrong in my favour? | Being right on overpriced bets |
| 2 | **Base rates** | How common is this before my evidence? | Treating rare+positive as certainty |
| 3 | **Variance / ruin** | What happens to *my* path if the bad branch hits? | Chasing the crowd average |
| 4 | **Kelly** | How big without deleting the edge? | Being right too loudly |

Formulas and traps: [references/four-laws.md](references/four-laws.md).  
Life / wealth scenarios: [references/scenarios.md](references/scenarios.md).  
Mission-map bridge: [references/mission-map-link.md](references/mission-map-link.md).

---

## Instructions

1. **Name the decision** — one fork on *this* path. If vague, Ask once.
2. **Law 1 EV** — list outcomes × rough odds. Mark favour / against / unknown. If unknown, say so; do not fake decimals.
3. **Law 2 base rate** — what prior does the evidence update? Ask “how many of these exist?” before reacting to a track record or alarm.
4. **Law 3 ruin** — can this path absorb a wipe (cash, housing, health, registration)? If yes and uninsured, **stop optimizing** and shrink / Wait / buy the negative-EV insurance.
5. **Law 4 size** — only if Laws 1–3 pass. Prefer **under-Kelly**. Oversize deletes edge.
6. **Honest exit** — pick one: `act sized` · `shrink path` · `Wait` · `Park` · `nothing-now`.
7. **One next act** — or explicitly `none`. Never stack five acts.
8. **mm_hook** — if a mission-map is in play, say which node this governs (Do/Risk/Wait/Park). Do not rewrite the DAG here.

### Flawed arithmetic red flags

- Reporting **average** return as what *you* will get
- Treating a **win rate** without a base rate of how many tried
- “Positive EV” games that **multiply** losses against remaining bankroll
- Doubling size because confidence rose (Law 4 failure)
- Inventing precision (`73.2%`) when inputs are vibes

### Allowed “nothing you can do now”

Use when the binding constraint is someone else’s date, a missing BankID/HITL step, a letter channel you already named, or cash that does not exist yet. Emit **Wait** + the signpost, then stop. That is not failure; that is Law 3 + honesty.

---

## Emit (required)

```markdown
## Uncertainty-laws
| Field | Value |
|-------|--------|
| **decision** | |
| **Law1 EV** | favour / against / unknown — one line |
| **Law2 base rate** | prior + what evidence updates |
| **Law3 ruin** | survive / threatened / absorbing-zero risk |
| **Law4 size** | under-Kelly hint or N/A |
| **honest exit** | act sized · shrink · Wait · Park · nothing-now |
| **next act** | one line or none |
| **mm_hook** | mission-map node or none |
```

Credit inspiration: public napkin framing of EV / Bayes / ruin / Kelly (e.g. Venix “Four Laws…” article). Formulas are centuries old; this skill is the **procedure**, not a market tip sheet.

---

## Done when

- Four laws considered in order (or stopped early at ruin)
- One honest exit + one next act or `none`
- No fake precision, no PII dump, no employer names in wealth/hire fog

## Limitations

- Not financial, legal, or medical advice.
- Does not replace mission-map critical path or eva-emptiness blank-sheet work.
- Numbers are operator-supplied; the skill refuses invented balances.
