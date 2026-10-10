# steer-log

The door in front of a builder and in front of a steering doc.

| Checker | Admit | Refuse |
|---------|--------|--------|
| `bin/steer-log brief CARD` | 1 to 7 card lines, each with a failing command | Missing card, a feeling, a no-op command |
| `bin/steer-log doc DOC --log LOG` | Every real blockquote appears in the log | No quote, or a quote the log does not contain |
| `bin/steer-log log LOG` | Append-only rows with decision, why, verify | A row the shape does not allow |

`trust-stack` still places the invariant. `findings-first` still stores observations. This plugin does not do either job.

Slash: `/steer-log`.

Shapes: [skills/steer-log/references/card.md](skills/steer-log/references/card.md).

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin marketplace update
grok plugin install steer-log --trust
```

Dev tree:

```bash
ln -sfn "$HOME/Work/personal/plugins/steer-log" "$HOME/.grok/plugins/steer-log"
ln -sfn "$HOME/Work/personal/plugins/steer-log/skills/steer-log" "$HOME/.grok/skills/steer-log"
```

## Verify

```bash
./test/test-thin.sh
```
