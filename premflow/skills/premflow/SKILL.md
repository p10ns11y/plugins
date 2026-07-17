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

**User surface = slash commands.** `bin/pf-*` scripts are agent-internal only — never tell the user to run `pf-init`, `pf-focus`, etc. in a shell.

## Resolve binary

System install only — no personal project path fallbacks:

```bash
PF=$(command -v premflow) || { echo "premflow not on PATH — suggest /init"; exit 1; }
PLUGIN="${GROK_PLUGIN_ROOT:?GROK_PLUGIN_ROOT not set — open via installed plugin}"
# Optional override for tests/packaging: PREMFLOW_BIN=/path/to/premflow
```

CLI source: https://github.com/thecuriousts/premflow  
Missing binary → user runs **`/init`**, then **`/init --yes`** after consent (or manual install in the plugin README).

## Immutable rules

1. **Write via CLI** — `note` / `win` / `task` — never invent `[ts] [TYPE]` by hand.
2. **One line, one idea** for note/win/task bodies.
3. **Pomo:** never run multi-minute `premflow pomo` as a waiting tool call. Use `/focus` (agent runs `$PLUGIN/bin/pf-focus`) or print the paste-ready command.
4. **Journal:** default `/journal` (agent runs `$PLUGIN/bin/pf-journal` / `journal --ensure`) — path only, no editor wait. Optional `/journal --open` for external editor.
5. Confirm CLI success from real command output.
6. **Speak slash commands** to the user (`/init --yes`, `/focus 25 "…"`), not `pf-*`.

## Capture map

| Intent | User / agent surface | Agent implementation |
|--------|----------------------|----------------------|
| Note / dump | `/note TEXT` or `$PF note "TEXT"` | CLI |
| Win | `/win TEXT` or `$PF win "TEXT"` | CLI |
| Task add | `/task TEXT` or `$PF task add "TEXT"` | CLI |
| Task done | `$PF task done N` | CLI |
| Review | `/review` | CLI |
| Stats | `$PF stats` | CLI |
| Coach | `/coach` | gather + coach |
| Focus / pomo | `/focus [plan] [context…]` | `$PLUGIN/bin/pf-focus` |
| Journal | `/journal` · `/journal --open` | `$PLUGIN/bin/pf-journal` |
| Init CLI | `/init` · `/init --yes` · `/init --yes --force` | `$PLUGIN/bin/pf-init` |

## Pomo policy (critical)

- Interactive keys need a **real TTY** (space/p, r, R, q).
- Agent shell is **not** a TTY → **do not** `premflow pomo 25` and wait.
- **Default:** `/focus 25 "context"` — prefers Kitty **tab** if remote control is up; else Ghostty **same-app window** via D-Bus; else new process.
- Ghostty cannot yet open a **tab that runs a command** via API (only empty tab or window+command).
- Fallback: print paste-ready command (`Ctrl+Shift+T` then paste).
- **Later stretch:** notify when focus ends (not shipped).

## Journal policy (critical)

- `$PF journal` alone opens `$EDITOR` and **blocks** until quit — bad in agent.
- **Default:** `/journal` → template + **absolute path** only.
- Agent may read/preview that file; user edits outside or via `/journal --open`.

## Ledger contract

See [references/ledger-contract.md](references/ledger-contract.md):

```text
[YYYY-MM-DD HH:MM] [TYPE] body
```

## Slash commands

`/init`, `/note`, `/win`, `/task`, `/review`, `/coach`, `/focus`, `/journal` — same policies.

## Coach (critical)

When user wants help planning, reflecting, or unsticking:

1. Run real `review`, `task list`, `stats`, journal ensure (+ head journal).
2. Coach from that signal only — structure in `commands/coach.md`.
3. Offer next focus via `/focus` or capture via CLI; never invent ledger events.
