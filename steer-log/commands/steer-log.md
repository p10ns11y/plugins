---
description: Admit a builder brief only with an invariant card. Admit a steering doc only when it quotes the log.
argument-hint: a builder brief, or a steering doc about to change
---

# /steer-log

Load skill **steer-log**. Open `references/card.md` only if the checker and the file disagree.

`$ARGUMENTS` is the brief or the doc. If it is empty, use the current turn.

## Immediate actions

1. Run `bin/steer-log brief` on the invariant card. No card, or exit 2: stop. Do not write the builder brief.
2. Run `bin/steer-log doc --log` before any steering-doc edit. Exit 2: stop. Do not quote the chat.
3. Append one log row for a decision that was actually made. Do not rewrite older rows.
4. On an admitted brief, load `trust-stack`. On an observation, load `findings-first`.

## Emit

```markdown
## Steer log
| Field | Value |
|-------|--------|
| **verdict** | admit or refuse |
| **reason** | |
| **next** | trust-stack, findings-first, or stop |
```
