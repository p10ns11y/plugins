---
name: capture-sweep
description: Sweep mail, calendar, chats, and pull requests into cards. Read only.
---

# capture-sweep

1. Run `bin/capture-sweep check-allows`. Stop if it exits 2. Load **capture-mail**, **capture-calendar**, **capture-pr**, and **capture-chat**.
2. Load **michelin-kitchen** `events-over-timers` when a source can subscribe. Do not install a server. This sweep stays a read.
3. Hand each card with kind `none` to **control-plane** `/feed`.
4. Admit to **mission-map** only a card that changes the next Do. `tstack-state ask admit` refuses a repeated ask. Never average contradictions.
5. Kind `money`, `send`, or `sign` is not a Do. Load **si**. Connectors do not pay, send, or sign.
6. Note the sweep in **pulse-memory**. Hint source `tstack/capture-sweep`, time ISO-8601, status `tool-verified`, hint kind `context`, lock `open`. Snippet is counts only.
7. Claude Code `/tstack:capture-sweep` and Grok `/workflow capture-sweep` follow [flows/specs/capture-sweep.md](../../../flows/specs/capture-sweep.md).
8. Portable: [flows/portable/capture-sweep.md](../../../flows/portable/capture-sweep.md). A fresh verifier runs before the actor. Only the actor writes `tstack-state`.
9. The card comes after that verifier. Sign off before the next flow.
