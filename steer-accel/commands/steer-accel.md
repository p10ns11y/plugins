---
description: Loop the five SpaceX steps for the stage the log has earned. Watch reads during a long stretch.
argument-hint: the stretch, the resume, or the stage you think you are in
---

# /steer-accel

Load skill **steer-accel**. Open `references/steps.md` for the earn table.

`$ARGUMENTS` is the stretch. If it is empty, use the current turn.

## Immediate actions

1. If this is a resume or a long stretch, create `.steer/loop.on`. On resume, `bin/steer-accel reset-reads .steer/reads`.
2. Write `.steer/now.md` from the stage log. A missing card forces `question`.
3. Run `bin/steer-accel check`. Exit 2: do `next`. Do not jump ahead.
4. Read the card in this session before a product edit. The hook records that read.
5. After the step lands, `bin/steer-accel append`.
6. Send a builder brief through `steer-log`. Send an invariant to `trust-stack`. Send an observation to `findings-first`.

## Emit

```markdown
## Steer accel
| Field | Value |
|-------|--------|
| **stage** | question, delete, simplify, accelerate, or automate |
| **verdict** | admit or refuse |
| **reason** | |
| **next** | |
| **watch** | on or off |
```
