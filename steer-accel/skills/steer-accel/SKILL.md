---
name: steer-accel
version: 0.1.0
description: >
  Use when a long stretch, a break, a context switch, or a coordinator about
  to do the work itself drops the brief. Triggers: /steer-accel, stage loop,
  acceleration, context drop, resumed session.
---

# steer-accel

One loop for a long stretch. The step comes from the stage log, not from how long the chat feels. Rules live in [references/steps.md](references/steps.md).

The mix is three checks on that same log. Dynamic means the earliest step the log has earned. Evolution means the log, not the chat, is what a resumed session reads. The repeat check sends a duplicated stage and verify back to `question`.

`steer-log` is the door for the card and the steering doc. `trust-stack` places the invariant. `findings-first` stores observations. `pulse-memory` may admit one tagged snippet after a break. This skill does not do those jobs.

## When

| Signal | Action |
|--------|--------|
| The stretch will outlast one sitting, or the session just resumed | Activate. Write `.steer/loop.on` and `.steer/now.md`. |
| A coordinator is about to edit the product | Activate. `actor: coordinator`. |
| A one-file fix with the card already green and no break | Skip. |
| The stretch is over | Delete `.steer/loop.on`. |

## Steps

1. On resume, run `bin/steer-accel reset-reads .steer/reads` before the next edit.
2. Read the card and the stage log. The hook records reads outside `.steer/`.
3. Set `stage` to what `bin/steer-accel check .steer/now.md .steer/stage.log --reads .steer/reads --session <id>` admits. Exit 2 means do that `next`, not the later step.
4. When the step lands, set `change`, then `bin/steer-accel append`.
5. A builder brief still goes through `steer-log` first.

## Emit

```markdown
## Steer accel
| Field | Value |
|-------|--------|
| **stage** | question, delete, simplify, accelerate, or automate |
| **verdict** | admit or refuse |
| **reason** | empty on admit |
| **next** | stage, reread, or question |
| **watch** | on or off |
```

## Do not

- Automate a step the log has not deleted and simplified
- Let a coordinator write product files with no card and no read in this session
- Leave the hook on after the stretch. No marker, no watch
- Treat the chat as the record of what stage you are in

## Done when

`check` printed `admit` for the stage you are on, or the write did not happen.
