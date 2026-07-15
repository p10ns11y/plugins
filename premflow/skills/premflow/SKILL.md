---
name: premflow
description: >-
  Capture notes, wins, tasks into premflow; review the day; coach from real
  ledger data; launch interactive pomo in an external terminal; ensure journal
  without hanging. Use when the user dumps a thought, wants note/win/todo/pomo/
  journal/review/coach while coding. Triggers: note, dump, capture, log this,
  premflow, remember, task add, win, journal, review my day, focus, pomo, coach,
  help me plan, evening coach.
---

# premflow — stay in session for capture; external TTY for focus & editor

**Mission:** Grok drives the **premflow** CLI. Fast writes stay in-session. Interactive **pomo** and **$EDITOR journal** never block the agent tool shell.

## Resolve binary

```bash
command -v premflow >/dev/null && PF=premflow || PF="$HOME/Work/personal/premflow/build/premflow"
PLUGIN="${GROK_PLUGIN_ROOT:-$HOME/Work/personal/plugins/premflow}"
```

## Immutable rules

1. **Write via CLI** — `note` / `win` / `task` — never invent `[ts] [TYPE]` by hand.
2. **One line, one idea** for note/win/task bodies.
3. **Pomo:** never run multi-minute `premflow pomo` as a waiting tool call. Use `$PLUGIN/bin/pf-focus` (external TTY) or print the command.
4. **Journal:** default `$PF journal --ensure` or `$PLUGIN/bin/pf-journal` — path only, no editor wait. Optional `--open` spawns editor externally.
5. Confirm CLI success from real command output.

## Capture map

| Intent | Do this |
|--------|---------|
| Note / dump | `$PF note "TEXT"` |
| Win | `$PF win "TEXT"` |
| Task add | `$PF task add "TEXT"` |
| Task done | `$PF task done N` |
| Review | `$PF review` |
| Stats | `$PF stats` |
| **Coach** | `/coach` — pull review + tasks + journal, then help (socratic, no invented facts) |
| Focus / pomo | `$PLUGIN/bin/pf-focus [plan] [context…]` or `--print-only` |
| Journal | `$PLUGIN/bin/pf-journal` → path; or `$PF journal --ensure` |

## Pomo policy (critical)

- Interactive keys need a **real TTY** (space/p, r, R, q).
- Agent shell is **not** a TTY → **do not** `premflow pomo 25` and wait.
- **Default:** `pf-focus 25 "context"` — prefers Kitty **tab** if remote control is up; else Ghostty **same-app window** via D-Bus; else new process.
- Ghostty cannot yet open a **tab that runs a command** via API (only empty tab or window+command).
- Fallback: print paste-ready command (`Ctrl+Shift+T` then paste).
- **Later stretch:** notify when focus ends (not shipped).

## Journal policy (critical)

- `$PF journal` alone opens `$EDITOR` and **blocks** until quit — bad in agent.
- **Default:** `journal --ensure` creates template (Grateful / intention / win sections) and **prints absolute path**.
- Agent may read/preview that file; user edits in their editor or `pf-journal --open`.

## Ledger contract

See [references/ledger-contract.md](references/ledger-contract.md):

```text
[YYYY-MM-DD HH:MM] [TYPE] body
```

## Slash commands

Plugin ships `/note`, `/win`, `/task`, `/review`, `/coach`, `/focus`, `/journal` — same policies.

## Coach (critical)

When user wants help planning, reflecting, or unsticking:

1. Run real `review`, `task list`, `stats`, `pf-journal` (+ head journal).
2. Coach from that signal only — structure in `commands/coach.md`.
3. Offer next focus via `pf-focus` or capture via CLI; never invent ledger events.

## Install

```bash
ln -sfn ~/Work/personal/plugins/premflow ~/.grok/plugins/premflow
# optional dual skill discovery:
ln -sfn ~/Work/personal/plugins/premflow/skills/premflow ~/.grok/skills/premflow
```

Reload Grok session or Plugins tab `r`.
