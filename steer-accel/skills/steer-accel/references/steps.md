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
delete | drop the second visual pass | pnpm test file-press | red | <card-sha256>
```

Five fields separated by ` | `. Stage, what changed, verify command, `red` or `green`, and the sha256 of the invariant card at append time. `append` runs the verify command and writes that result. A three-field row from before this rule has no result.

## reads

The hook appends `session<TAB>path` to `.steer/reads` when a file outside `.steer/` is read during the stretch. A write or a shell command needs one read in the same session. Reading `.steer/` does not count. `steer-accel reset-reads` clears the file at the start of a resumed session.

## Repeat

`append` runs the verify command. Exit 0 writes `green`. Any other exit writes `red`. The next pass is refused while that result is `red` and the card file's sha256 is unchanged. A changed card is admitted only when `steer-log` accepts it, which keeps the seven-line cap. Replacing a line is how a card gets tighter. An eighth line stays refused.

A `green` row with the same stage and the same verify as `now.md` is still refused. Go back to `question`. This loop does not rewrite a model.

## Watcher

Create `.steer/loop.on` when the stretch is long, the session resumed, or a coordinator might do the work. The hook then records reads and refuses a write or a shell command the checker refuses. Delete `.steer/loop.on` when the stretch ends. With no marker, the hook allows the call.
