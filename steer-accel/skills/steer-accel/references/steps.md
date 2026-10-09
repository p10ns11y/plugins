# Steps the loop can be on

Order is fixed. A later step is earned only when the stage log already shows the earlier work.

| Stage | Earned when |
|-------|-------------|
| `question` | Always. Use it when the card is missing, or the last row repeated. |
| `delete` | `card` is a path, not `-`. |
| `simplify` | `card` is a path, not `-`. |
| `accelerate` | `card` is a path, and the log already has `delete` or `simplify`. |
| `automate` | `card` is a path, and the log has both `delete` and `simplify`. |

## now.md

One field per line.

```text
stage: question
actor: builder
resumed: no
card: INVARIANT.md
verify: pnpm test file-press
change: -
```

`actor` is `builder` or `coordinator`. `resumed` is `yes` or `no`. `card: -` means no card. `change: -` means the step has not landed. A landed step has a non-empty `change` that is not `-`.

## stage.log

One row per landed step. Append only.

```text
delete | drop the second visual pass | pnpm test file-press
```

Three fields separated by ` | `. Stage, what changed, verify command.

## reads

The hook appends `session<TAB>path` to `.steer/reads` when a file outside `.steer/` is read during the stretch. A write or a shell command needs one read in the same session. Reading `.steer/` does not count. `steer-accel reset-reads` clears the file at the start of a resumed session.

## Repeat

If the last log row has the same stage and the same verify as `now.md`, the checker refuses. Change the verify or go back to `question`. That is the recursive step. It does not rewrite a model.

## Watcher

Create `.steer/loop.on` when the stretch is long, the session resumed, or a coordinator might do the work. The hook then records reads and refuses a write or a shell command the checker refuses. Delete `.steer/loop.on` when the stretch ends. With no marker, the hook allows the call.
