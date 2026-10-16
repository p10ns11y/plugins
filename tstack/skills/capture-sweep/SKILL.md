---
name: capture-sweep
description: Sweep mail, calendar, chats, and pull requests into cards. Read only.
---

# capture-sweep

1. Run `bin/capture-sweep check-allows`. Stop if it exits 2. Load **capture-mail**, **capture-calendar**, **capture-pr**, and **capture-chat**.
2. Load **michelin-kitchen** `events-over-timers` when a source can subscribe. Do not install a server. This sweep stays a read.
3. Hand each card with kind `none` to **control-plane** `/feed`.
4. Admit to **mission-map** only a card that changes the next Do. Never average contradictions.
5. Kind `money`, `send`, or `sign` is not a Do. Load **si**. Connectors do not pay, send, or sign.
6. Note the sweep in **pulse-memory**. Hint source `tstack/capture-sweep`, time ISO-8601, status `tool-verified`, hint kind `context`, lock `open`. Snippet is counts only.

Claude Code: `/tstack:capture-sweep`. Reader agents are read-only. Only the actor writes `tstack-state`.
The script returns cards. It does not post, pay, or sign.
