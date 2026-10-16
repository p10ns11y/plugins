# mine-corrections

Laws: [flows/bend/LAWS.bend](../bend/LAWS.bend)

Args: `since`, `paths`

| Phase | Mode | Does |
|-------|------|------|
| Mine | read | one reader per path |
| Cluster | read | group repeated corrections |
| Filter | fresh verifier | keep a rule that would have prevented a real miss |

Result card, only after the fresh verifier: rules whose prevented flag is true

The filter is the fresh verifier. The rule card comes after the filter. Empty paths still run that verifier, then return an empty rule card. The flow does not edit files.

Sign-off: stop. A person signs off before the next flow starts. No merge without a review verdict. Send, pay, and sign stay outside the flow.

Variants:

- Claude: [pulse-memory/workflows/mine-corrections.js](../../pulse-memory/workflows/mine-corrections.js)
- Grok: [pulse-memory/.grok/workflows/mine-corrections.rhai](../../pulse-memory/.grok/workflows/mine-corrections.rhai)
- Portable: [flows/portable/mine-corrections.md](../portable/mine-corrections.md)
