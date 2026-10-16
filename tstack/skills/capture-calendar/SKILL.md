---
name: capture-calendar
description: Read a calendar into one card. Never pay.
---

# capture-calendar

1. Run `bin/capture-sweep check-allows`. Stop if it exits 2.
2. Read `connectors/calendar.allow`. Call a connected read only when its name is on that list. This repo has no calendar client. Do not invent a tool name. Do not install a server. Do not ask for keys.
3. Write a local record and run `bin/capture-sweep emit` on it. The card shape is `references/cards.md`.
4. Do not copy an event title into `ask`. Use `A calendar block changed.` unless the record is already a clean sentence.
5. Kind `money`, `send`, or `sign` stops the connector. Load **si**. Do not create, update, delete, respond, pay, or sign.
