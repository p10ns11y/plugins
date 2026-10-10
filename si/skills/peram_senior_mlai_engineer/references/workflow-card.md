# Workflow card

Every durable profile emits this card before code. One surface per card.

```text
surface:     data | si-native | si-service | deterministic-saas | infra | devex
invariant:   one sentence that must stay true
states:      named → … → done, including the failure edge
owned:       the artifact this change writes
writers:     who may write it (person, service, never "the model")
verify:      the check that fails if the invariant breaks
refuse:      what this workflow will not decide
```

## Rules

- `writers` is never "the model" for a committed record, a permission, or a price.
- `states` includes empty, failed, or rejected when a person can see that state.
- `verify` is a command, a test name, or a replay. A feeling is not a verify line.
- One card per change. A second surface gets a second card and a second profile.

Spine: [../SKILL.md](../SKILL.md).
