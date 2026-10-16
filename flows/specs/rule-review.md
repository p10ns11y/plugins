# rule-review

Args: `diff`, `rulesFile`

| Phase | Mode | Does |
|-------|------|------|
| Split | read | list each hard rule |
| Verify | fresh read | one SI per rule |
| Skeptic | fresh verifier | keep a flag only when the evidence line holds |

Result card, only after the fresh verifier: flags, each with ruleId and evidence

The skeptic is the fresh verifier. The flag card comes after the skeptic. Missing args still run that verifier, then return an empty flag card.

Sign-off: stop. A person signs off before the next flow starts. No merge without a review verdict. Send, pay, and sign stay outside the flow.

Variants:

- Claude: [trust-stack/workflows/rule-review.js](../../trust-stack/workflows/rule-review.js)
- Grok: [trust-stack/.grok/workflows/rule-review.rhai](../../trust-stack/.grok/workflows/rule-review.rhai)
- Portable: [flows/portable/rule-review.md](../portable/rule-review.md)
