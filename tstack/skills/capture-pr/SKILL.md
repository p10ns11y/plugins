---
name: capture-pr
description: Read pull requests into one card. Never merge or comment.
---

# capture-pr

1. Run `bin/capture-sweep check-allows`. Stop if it exits 2.
2. Read `connectors/pr.allow`. The only live command is `bin/capture-sweep live-pr`.
3. If that command prints `pr: unavailable`, leave that result. Do not install `gh` and do not ask for keys. Do not print a `gh` error.
4. A local record still goes through `bin/capture-sweep emit`. The card shape is `references/cards.md`.
5. Do not copy a title into `ask`. The live ask is `A pull request is waiting.`
6. Kind `money`, `send`, or `sign` stops the connector. Load **si**. Do not comment, merge, close, or sign.
