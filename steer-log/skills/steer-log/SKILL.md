---
name: steer-log
version: 0.1.0
description: >
  Use when a builder brief, a steering-doc edit, or a quote from a long chat
  is in play. Triggers: /steer-log, invariant card, steering doc, steer log.
---

# steer-log

Run `bin/steer-log` before a builder starts, and before a steering doc changes. Exit 2 means the edit does not happen. Shapes live in [references/card.md](references/card.md). This file does not restate them.

`trust-stack` places the invariant. `findings-first` stores observations. This skill only opens or shuts the door.

Upstream name: load `aihero-map`.

## When

| Signal | Action |
|--------|--------|
| A builder brief is about to be written or handed off | Activate |
| A steering doc is about to change | Activate |
| The checker already admitted the card and the open question is which layer holds it | Skip. Load `trust-stack`. |
| The note is an observation, not a decision that was made | Skip. Load `findings-first`. |
| An alignment interview is still open | Activate. It ends when `brief` admits the card. |

## Steps

1. `bin/steer-log brief <card>` before the brief. Refuse means stop.
2. `bin/steer-log doc <doc> --log <log>` before the doc edit. Refuse means stop. Do not fill the doc from the chat.
3. `bin/steer-log log <log>` after a new row. Refuse means the older row changed. Do not rewrite `LOG.prior` by hand.
4. `bin/steer-log pre <dir>` before a design pass or a deploy sentence. Refuse means stop.
5. Admitted brief: load `trust-stack`. Observation: load `findings-first`. `findings-first` still appends, clusters, then one pull request per theme. `shared-scripts` still writes the verify script.
5. An open alignment interview asks until every card line has a failing command. It does not write the spec. After `brief` admits the card, the spec is `craft`.

## Emit

```markdown
## Steer log
| Field | Value |
|-------|--------|
| **verdict** | admit or refuse |
| **reason** | empty on admit |
| **next** | trust-stack, findings-first, or stop |
```

## Do not

- Add a design skill, a taste score, or a checker that calls a model
- Reconstruct a stretch of work from the current turn
- Treat a feeling with no failing command as a card line

## Done when

The checker printed `admit`, or the brief and the doc edit did not happen.
