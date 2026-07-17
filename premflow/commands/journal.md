---
description: Ensure today's premflow journal (template) without blocking on editor
argument-hint: "[--open] optional external editor"
---

# /journal — ensure path; never hang the agent on $EDITOR

Assumes `premflow` is on PATH. If missing → tell user to run `/init` (then `/init --yes` with consent).

## Policy (do not violate)

- Bare `premflow journal` opens `$EDITOR` and **blocks until the editor exits** — **not** the default in-agent path.
- **Default:** ensure today's file + print absolute path (template matches C writer).
- User-facing: **`/journal`** and **`/journal --open`**. `pf-journal` is agent-internal only.

## User examples

```text
/journal
/journal --open
```

## Agent action (default)

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
"$PLUGIN/bin/pf-journal"
# equivalent CLI: premflow journal --ensure
```

Then: show path; optional short preview of the file (head). User can edit outside.

## Agent action (external editor, non-blocking)

If `$ARGUMENTS` contains `--open`:

```bash
"$PLUGIN/bin/pf-journal" --open
```

Still does **not** wait for the editor process.
