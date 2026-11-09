---
description: Audit AI tools and agent flows for waste. Ledger, myth cards, irreversible checks, frontline interviews.
argument-hint: optional process name or org context
---

# /ai-flow-audit

Load skill **ai-flow-audit**. Pull templates from `references/` only as needed.

`$ARGUMENTS` = the process or context. If empty, use the current thread's tool or agent flow.

## Immediate actions

1. Confirm **one process** and a sample window.
2. Offer **interview-guide** order: frontline first.
3. Fill or sketch **waste-ledger** rows for each flow.
4. Add **myth cards** only when two evidence types exist.
5. Run **irreversible-checklist** for every agent step.
6. Emit kill / keep / test. No PII or live customer data in the emit.
7. For a full walkthrough, open `examples/paper-lantern-worked-example.md` and say it is fictional.

## Emit

Use the table in the skill. Include next evidence in one line.
