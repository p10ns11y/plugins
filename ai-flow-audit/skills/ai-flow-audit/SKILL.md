---
name: ai-flow-audit
version: 0.1.0
description: >
  Audit your own AI tools and agent flows for waste before it lands. Waste ledger,
  myth cards, irreversible-action checks, and frontline-first interviews. Use for
  /ai-flow-audit, SMB or solo dev flow review, agent spend review, or myth busting
  before automation ships.
metadata:
  author: p10ns11y <9104920+p10ns11y@users.noreply.github.com>
  tags:
    - ai-audit
    - agent-flow
    - waste
    - myth-card
    - hitl
    - small-business
---

# ai-flow-audit

> **Load rule:** Templates use placeholders only. No live customer data in emits. Money, send, pay, delete, merge, and publish stay human-checked. Not legal or tax advice.

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#7c3aed', 'primaryTextColor': '#fff', 'primaryBorderColor': '#5b21b6', 'secondaryColor': '#06b6d4', 'tertiaryColor': '#fbbf24', 'lineColor': '#6366f1', 'fontSize': '14px'}}}%%
flowchart TB
  subgraph listen["Listen"]
    INT[Frontline interview]
  end
  subgraph map["Map"]
    INV[Flow inventory]
    LED[Waste ledger rows]
  end
  subgraph test["Test claims"]
    MYTH[Myth cards]
    AUTO[Autopsy rows]
  end
  subgraph guard["Guard"]
    IRR[Irreversible checklist]
  end
  subgraph decide["Decide"]
    KKT[Kill / keep / test]
  end
  INT --> INV
  INV --> LED
  LED --> MYTH
  LED --> AUTO
  MYTH --> IRR
  AUTO --> IRR
  IRR --> KKT
  style listen fill:#a78bfa,stroke:#5b21b6,color:#1e1b4b
  style map fill:#67e8f9,stroke:#0e7490,color:#164e63
  style test fill:#fde68a,stroke:#d97706,color:#78350f
  style guard fill:#fda4af,stroke:#e11d48,color:#881337
  style decide fill:#86efac,stroke:#16a34a,color:#14532d
```

## Spec

| Piece | File | Job |
|-------|------|-----|
| Waste ledger | [references/waste-ledger.md](references/waste-ledger.md) | One row per flow: tool, monthly cost, time saved or lost, waste type, fix |
| Myth card | [references/myth-card.md](references/myth-card.md) | Claim, evidence, cost of believing, audit question |
| Irreversible checklist | [references/irreversible-checklist.md](references/irreversible-checklist.md) | Every undoable agent action plus fixed human check |
| Interview guide | [references/interview-guide.md](references/interview-guide.md) | Frontline first, then manager, then sponsor |
| Worked example | [../../examples/paper-lantern-worked-example.md](../../examples/paper-lantern-worked-example.md) | Fictional company end to end |

**Evidence bar:** A myth or maturity claim needs at least two of: time sample, money sample, frontline quote, failed-task autopsy. Do not score on assertion alone.

Slash: `/ai-flow-audit`. Match “waste ledger”, “myth card”, “audit AI flow”, “agent waste”.

## Activate / skip

| Signal | Action |
|--------|--------|
| New AI tool or agent flow in a small team | Activate |
| Spend or rework feels off but story sounds great | Activate |
| Single file fix with known verify | Skip |
| Pure math uncertainty with no tools | Prefer **uncertainty-laws** |

## Instructions

1. Pick **one process** and a sample window. Set a stop date if evidence stays thin.
2. Run **interview-guide** frontline first. Capture evidence IDs, not names.
3. Fill **waste-ledger** inventory and time or money samples. Mark unknowns.
4. Name each flow's **rung** (Ask → Do → Automate → Staff) before proposing a fix. Move at most one rung per change.
5. Write **myth cards** only when the evidence bar is met.
6. Walk **irreversible-checklist** for every automated or agent step in the flow.
7. Emit kill / keep / test with owners and next check dates.
8. Point the user at the fictional worked example when they want a full walkthrough.

## Emit (required)

```markdown
## AI flow audit
| Field | Value |
|-------|--------|
| **process** | |
| **sample window** | |
| **flows in ledger** | count |
| **myth cards** | count (supported / candidate) |
| **irreversible acts** | count unchecked |
| **measurable leakage** | range or unknown |
| **kill / keep / test** | short list |
| **next evidence** | one item |
```

## Hard nos

- No PII, tokens, emails, phone numbers, or real employer names in emits.
- No fake precision when inputs are estimates.
- No promises of savings before evidence is reviewed.
