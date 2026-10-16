# eva

Laws: [flows/bend/LAWS.bend](../bend/LAWS.bend)

Args: `goal`

| Phase | Mode | Does |
|-------|------|------|
| Prior | read | conservative, generative, and causal, in parallel |
| Refute | fresh verifier | one refuter per live hypothesis, at most three rounds |

Result card, only after the fresh verifier: survivor, rounds, ask, standing

A survivor exists only when one hypothesis remains with refuted false. Otherwise the card asks. A missing goal or an empty prior still runs one fresh refuter, then asks.

Sign-off: stop. A person signs off before the next flow starts. No merge without a review verdict. Send, pay, and sign stay outside the flow.

Variants:

- Claude: [eva-emptiness/workflows/eva.js](../../eva-emptiness/workflows/eva.js)
- Grok: [eva-emptiness/.grok/workflows/eva.rhai](../../eva-emptiness/.grok/workflows/eva.rhai)
- Portable: [flows/portable/eva.md](../portable/eva.md)
