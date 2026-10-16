---
name: capture-chat
description: Read chats into one card. Never post.
---

# capture-chat

1. Run `bin/capture-sweep check-allows`. Stop if it exits 2.
2. Read `connectors/chat.allow`. Call a connected read only when its name is on that list. This repo has no chat client. Do not invent a tool name. Do not install a server. Do not ask for keys.
3. Write a local record and run `bin/capture-sweep emit` on it. The card shape is `references/cards.md`.
4. Do not copy a chat body into `ask`. Use `A chat needs a look.` unless the record is already a clean sentence.
5. Kind `money`, `send`, or `sign` stops the connector. Load **si**. Do not post, send, pay, or sign.
