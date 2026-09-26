# trust-stack

Puts one invariant on the earliest layer that can hold it.

| Layer | Holds it by |
|---|---|
| `shape` | Making the wrong change hard to write. |
| `check` | A compiler or analyzer that fails the build. |
| `watch` | A rule or review bot, then an agent fix. |
| `skill` | A lesson written once, after a real miss. |
| `guide` | A person. This layer is hitl. |

The codebase is the agent's memory, so a workaround spreads. Delete it and move the invariant earlier. One owner runs the real check. This plugin does not merge.

Intelliarch loads it when the goal is trust, review, a repeated miss, or fan-out. pstack remains the playbook when it is installed.

## Install

```bash
grok plugin install ./trust-stack --trust
# slash: /trust-stack
```

## Bend

When using Bend, from `bend/`:

- run `bend guide` to learn it
- use `LAWS.bend` to keep important rules
- run `bend PROOF.bend` before committing
- parallelize the code whenever possible

## Tests

```bash
./trust-stack/test/test-thin.sh
```

Talk credit: [NOTICE.md](NOTICE.md).
