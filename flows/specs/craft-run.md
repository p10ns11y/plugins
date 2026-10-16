# craft-run

Args: `change`

| Phase | Mode | Does |
|-------|------|------|
| Spec | read | acceptance before any code |
| Code | write | tests and the implementation |
| Clean | write | CRAP on touched functions |
| Harden | write | mutation score on non-Bend code |
| QA | fresh verifier | does not implement |

Result card, only after the fresh verifier: spec, acceptance, step, touched, crap_max, mutation, scout, next

QA is the fresh verifier. The result card is emitted only after QA.

Sign-off: stop. A person signs off before the next flow starts. No merge without a review verdict. Send, pay, and sign stay outside the flow.

Variants:

- Claude: [craft/workflows/craft-run.js](../../craft/workflows/craft-run.js)
- Grok: [craft/.grok/workflows/craft-run.rhai](../../craft/.grok/workflows/craft-run.rhai)
- Portable: [flows/portable/craft-run.md](../portable/craft-run.md)
