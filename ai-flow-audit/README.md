# ai-flow-audit

**Free public kit** to audit AI tools and agent flows before waste lands.

Waste ledger, myth cards, irreversible-action checks, frontline-first interviews, plus a **fictional** worked example.

| Use this when | Skip when |
|---------------|-----------|
| A new agent or AI tool joins a small team | One file fix with known verify |
| Spend or rework feels wrong | Pure probability fog → **uncertainty-laws** |
| You need a reusable template, not a consultant deck | |

Slash: `/ai-flow-audit`.

---

## Surfaces

| Surface | Job | Invoke |
|---------|-----|--------|
| **Skill** | Run the audit procedure | `/ai-flow-audit` or auto-match |
| **Plugin** | Bundle skill, command, refs, example | `grok plugin install ai-flow-audit --trust` |
| **References** | Copy-ready templates | `skills/ai-flow-audit/references/` |

---

## Kit contents

1. [Waste ledger](skills/ai-flow-audit/references/waste-ledger.md) — flows, tools, cost, time, waste type, fix
2. [Myth card](skills/ai-flow-audit/references/myth-card.md) — claim, evidence, cost of believing
3. [Irreversible checklist](skills/ai-flow-audit/references/irreversible-checklist.md) — send, pay, delete, merge, publish, and fixed human checks
4. [Interview guide](skills/ai-flow-audit/references/interview-guide.md) — frontline first
5. [Paper Lantern Labs example](examples/paper-lantern-worked-example.md) — fictional end to end

---

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin marketplace update
grok plugin install ai-flow-audit --trust
```

Cursor:

```bash
agent plugin marketplace add https://github.com/p10ns11y/plugins.git
```

Then install **ai-flow-audit** from Marketplace.

---

## Verify

```bash
./test/test-thin.sh
```

---

## Hard nos

- No PII, tokens, emails, or real employer names in emits or fixtures.
- No fake precision on estimates.
- No promises of savings before evidence is reviewed.
