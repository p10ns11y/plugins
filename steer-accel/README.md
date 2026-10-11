# steer-accel

A loop for a long stretch. Five steps, in order. Question the requirement, delete, simplify, accelerate, automate. The stage log says which of those the work has earned. The chat does not.

| Check | What it stops |
|-------|----------------|
| Earn table | Accelerate before a delete or a simplify. Automate before both. |
| Repeat | A red verify blocks the next pass until the card changes and still passes `steer-log`. A green row with the same stage and verify is refused. |
| Session reads | A product write after a break, or by a coordinator, with nothing read in this session. |
| Card | A coordinator with `card: -`. |

The hook runs on read, write, and shell. It watches when `.steer/loop.on` exists, or when `actor: coordinator` is in `.steer/now.md`. A coordinator does not also need the marker file. A crash while the watch is on denies the call. Create the marker for a long stretch. Delete it when the stretch ends. With neither signal, the hook allows the call.

Cursor `preToolUse` on Write and Edit uses the same script and fails closed. The hook does not run during token generation or compaction.

`steer-log` still admits the brief. `trust-stack` still places the invariant. `findings-first` still stores observations.

Slash: `/steer-accel`.

Earn table: [skills/steer-accel/references/steps.md](skills/steer-accel/references/steps.md).

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin marketplace update
grok plugin install steer-accel --trust
```

Dev tree:

```bash
ln -sfn "$HOME/Work/personal/plugins/steer-accel" "$HOME/.grok/plugins/steer-accel"
ln -sfn "$HOME/Work/personal/plugins/steer-accel/skills/steer-accel" "$HOME/.grok/skills/steer-accel"
```

Review `hooks/hooks.json` and `bin/steer-accel-pretool.sh` before `--trust`. The script allows a call when the watch is off. When the watch is on, a crash denies the call.

Cursor wires `beforeShellExecution`, `beforeReadFile`, and `preToolUse` for Write and Edit to the same script. Grok `PreToolUse` on Write and Edit is the write watch.

## Verify

```bash
./test/test-thin.sh
```
