---
description: Ensure today's premflow journal (template) without blocking on editor
argument-hint: "[--open] optional external editor"
---

# /journal — ensure path; never hang the agent on $EDITOR

Assumes `premflow` is on PATH (system install). If missing → run `/init`.

## Policy (do not violate)

- Bare `premflow journal` opens `$EDITOR` and **blocks until the editor exits** — **not** the default in-agent path.
- **Default:** ensure today's file + print absolute path (template matches C writer).

## Default action

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
# Preferred helper (wraps journal --ensure; uses PATH via pf-resolve)
"$PLUGIN/bin/pf-journal"

# Equivalent:
# premflow journal --ensure
```

Then: show path; optional short preview of the file (head). User can edit outside.

## Optional external editor (non-blocking spawn)

If user wants editor now and `$ARGUMENTS` contains `--open`:

```bash
"$PLUGIN/bin/pf-journal" --open
```

Still does **not** wait for the editor process.
