# capture-sweep

Laws: [flows/bend/LAWS.bend](../bend/LAWS.bend)

Args: none

| Phase | Mode | Does |
|-------|------|------|
| Read | read | mail, calendar, chat, and pull requests, in parallel |
| Verify | fresh verifier | check the cards, read only |
| Act | final write | the only writer of tstack-state |

Result card, only after the fresh verifier: cards, ok, stored, held

The verifier runs before Act. Only Act writes. Kind money, post, or sign is held for a person.

Sign-off: stop. A person signs off before the next flow starts. No merge without a review verdict. Send, pay, and sign stay outside the flow.

Variants:

- Claude: [tstack/workflows/capture-sweep.js](../../tstack/workflows/capture-sweep.js)
- Grok: [tstack/.grok/workflows/capture-sweep.rhai](../../tstack/.grok/workflows/capture-sweep.rhai)
- Portable: [flows/portable/capture-sweep.md](../portable/capture-sweep.md)
