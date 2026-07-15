# premflow ledger contract

Human- and agent-readable source of truth under `~/.premflow/`. Frozen from shipped writers (`append_entry`, effects, pomo, `complete_task`).

## Directory layout

| Path | Role |
|------|------|
| `~/.premflow/log.txt` | Append-only activity stream |
| `~/.premflow/todo.txt` | Open tasks (one active line each) |
| `~/.premflow/journal/journal-YYYY-MM-DD.txt` | Daily freeform markdown template |
| `~/.premflow/config.txt` | Sounds (and future keys) |

Root is `$HOME/.premflow` via `data_path` in `src/core.c`.

## Line grammar (log + todo)

Every structured line is **one physical line**:

```text
[YYYY-MM-DD HH:MM] [TYPE] body text here
```

| Field | Rule | Evidence |
|-------|------|----------|
| Timestamp | Local time, zero-padded, space between date and time | `append_entry` → `strftime(..., "%Y-%m-%d %H:%M")` |
| Separator | `] ` then type | `fprintf(f, "[%s] %s %s\n", ts, prefix, text)` |
| TYPE | Square brackets, uppercase token | Writers pass `"[NOTE]"`, `"[WIN]"`, … |
| Body | Single line; no raw newlines (collapsed to spaces on write) | `ledger_sanitize_body` + `append_entry` |
| EOL | `\n` | `append_entry` |

Regex-friendly shape:

```text
^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\] \[[A-Z]+\] .+$
```

## Types and files

| TYPE | File | Writer | Body meaning |
|------|------|--------|--------------|
| `NOTE` | `log.txt` | `premflow note …` | Thought / dump |
| `WIN` | `log.txt` | `premflow win …` | Win / gratitude |
| `POMO` | `log.txt` | focus segment complete | Context label or `pomodoro session` |
| `DONE` | `log.txt` | `premflow task done n` | Completed task **title only** (no nested `[TODO]`) |
| `TODO` | `todo.txt` | `premflow task add …` | Open work item |

Journal files are **not** type-tagged ledger lines; they are human markdown opened via `$EDITOR`.

## Anti-patterns (do not write)

| Bad | Why |
|-----|-----|
| Multi-line body in log/todo | Breaks line scanners / review |
| Nested types: `[DONE] [ts] [TODO] foo` | Historical bug shape; hard for humans and agents |
| Hand-editing without CLI | Missed timestamps / inconsistent types |
| Putting tasks only in `log.txt` | Active set is `todo.txt` |
| Inventing log lines in chat without CLI | Format drift |

## Historical debt

Older `log.txt` may contain:

```text
[2026-04-11 23:18] [DONE] [2026-04-11 23:18] [TODO] Test task to complete
```

New completions strip to:

```text
[YYYY-MM-DD HH:MM] [DONE] Test task to complete
```

Readers (`review`) should tolerate old lines; writers must not produce nested types.

## Agent / Grok conventions

1. **Capture via CLI** — `premflow note|win|task add|task done|pomo …`
2. **One idea per note** — short single-line body
3. **POMO context** — `premflow pomo 25 ship review PR` so the log is searchable
4. **Read path** — prefer `premflow review` / `task list` over dumping whole `log.txt`
5. **Never** invent fake timestamps

## CLI → type map

| Command | Effect |
|---------|--------|
| `premflow note TEXT` | append `[NOTE]` |
| `premflow win TEXT` | append `[WIN]` |
| `premflow task add TEXT` | append `[TODO]` to todo |
| `premflow task done N` | remove todo #N; append `[DONE]` title |
| `premflow pomo [plan] [context…]` | on focus end: `[POMO]` body |

## Related

- Engine / UX: `designs/pomo-interactive.md`, `designs/coming-next.md` §8 / §15
- Code: `src/core.c` (`append_entry`, `ledger_sanitize_body`, `complete_task`), `src/effects.c`
