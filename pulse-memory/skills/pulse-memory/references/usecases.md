# How to run pulse-memory (modes, paths, as_of)

The **skill** (`/pulse-memory`) is turn mode: no files, no clock.  
The **workflow** (`/workflow pulse-memory`) is a file cycle. It has **no wall clock** — you must pass `as_of`.

Do not dump vaults. Pulse against **one next action**.

## Args (workflow)

| Arg | Required when | What it is |
|-----|----------------|------------|
| `mode` | optional | `both` (default) · `thinking` · `harness` |
| `thinking_path` | `both` or `thinking` | Operator dump: session note, scratch, “what I believe / asked” |
| `harness_path` | `both` or `harness` | Machine SoT: Dashboard, Career, `next_action`, Card, DB export |
| `as_of` | **always** (workflow) | ISO-8601. Tags every untimed claim. Example `2026-08-29T15:00:00Z` |
| `next_action` | strongly recommended | The only reason to inject. Default: `unknown next action` (almost everything rejects) |
| `pulse_out` | optional | Markdown path to overwrite (else scratch `pulse.md` only) |

Turn mode has **no** `as_of` arg — stamp `time` from the user message or `unknown`.

## What goes in each file

**thinking_path** — messy, first-person, may contradict itself:

- `Projects/*/sessions/YYYY-MM-DD.md`
- a scratch dump you just wrote
- plugin `test/fixtures/thinking.md`
- “I want 10 roles then 4–6 applies then cash-first”

**harness_path** — what the system currently treats as true:

- `UI/Dashboard.md` · `Areas/Career.md` · `Projects/collab-finder/README.md` (`next_action`)
- `private/career/2026-08-29-cash-first.md` (private sitting)
- Control Card / SQLite dump
- plugin `test/fixtures/harness.md`

If thinking and harness disagree, **do not average**. Later + higher `status` wins, else **not in the evidence**.

---

## Mode 1 — Turn (`/pulse-memory`)

Use when the contradiction is **in this chat** (no need to scan disks).

```text
/pulse-memory next action: send 4 cash-first Sweden IC applies.
Dashboard still says 2–3. I locked 4 later the same day.
```

Agent: tag claims, emit ≤8 pulses, fix or list conflicts. No workflow.

**as_of:** implied by the user turn (e.g. 2026-08-29). If they did not date it, `time: unknown`.

---

## Mode 2 — Both files (default workflow)

Use when operator dump and live notes have drifted.

```json
{
  "mode": "both",
  "thinking_path": "/home/you/life-os/Projects/collab-finder/sessions/2026-08-29.md",
  "harness_path": "/home/you/life-os/UI/Dashboard.md",
  "as_of": "2026-08-29T20:30:00Z",
  "next_action": "send 4 cash-first Sweden IC applications",
  "pulse_out": "/home/you/life-os/private/career/2026-08-29-pulse.md"
}
```

Slash: `/workflow pulse-memory` then paste that object as args.

Shipped fixture (this plugin):

```json
{
  "mode": "both",
  "thinking_path": "<plugin>/test/fixtures/thinking.md",
  "harness_path": "<plugin>/test/fixtures/harness.md",
  "as_of": "2026-08-29T15:00:00Z",
  "next_action": "send 4 cash-first Sweden IC applications"
}
```

Expect: sitting cap **4**, stretch parked, 2–3 / 10-mix in `rejected[]`.

---

## Mode 3 — Thinking only

Use when you have a dump and have not updated Dashboard yet (admit *intent* before harness catch-up).

```json
{
  "mode": "thinking",
  "thinking_path": "/home/you/life-os/private/career/2026-08-29-cash-first.md",
  "as_of": "2026-08-29T18:00:00Z",
  "next_action": "write the public Dashboard sitting line"
}
```

Do **not** pass `harness_path`. Workflow pauses if `mode=thinking` and thinking path is empty.

---

## Mode 4 — Harness only

Use when you trust the files as SoT and want a pulse for the next agent turn (no extra dump).

```json
{
  "mode": "harness",
  "harness_path": "/home/you/life-os/Projects/collab-finder/README.md",
  "as_of": "2026-08-29T20:30:00Z",
  "next_action": "send 4 cash-first Sweden IC applications"
}
```

Typical harness hits: YAML `next_action`, Career current-focus, Map current focus.

---

## Mode 5 — Periodic (scheduler)

The workflow **cannot sleep**. A host scheduler fires it and **must** inject a fresh `as_of`.

```json
{
  "mode": "both",
  "thinking_path": "/home/you/.grok/scratch/thinking.md",
  "harness_path": "/home/you/life-os/UI/Dashboard.md",
  "as_of": "<scheduler fills ISO-8601 now>",
  "next_action": "<copy from Dashboard red line>"
}
```

Interval 30–60 min is enough. Always-on per-tool-call hooks are Winds — do not do that.

If `as_of` is missing, the run **pauses** (`Pass args.as_of`). That is why `/pulse-memory-2` cancelled in 0s when the slash dump had no files.

---

## `as_of` rules

| Do | Don’t |
|----|--------|
| ISO-8601 with timezone: `2026-08-29T15:00:00Z` | `now`, `today`, omitting the field |
| Use the time of the **sitting**, not file mtime, when they disagree | Let similarity fetch Tuesday’s constraint after Wednesday revoked it |
| Untimed claims inside a file inherit `as_of` | Invent a clock inside the Rhai |

`time` on a pulse may still be a date from the file (`2026-08-28`) if the file dated the claim. `as_of` is the **scan clock**.

---

## Worked sitting (29 Aug 2026)

| Piece | Path / value |
|-------|----------------|
| thinking | session + cash-first private note (operator locked 4, parked stretch, citizen, return 18 Sep) |
| harness | Dashboard (was 2–3), Career, collab-finder `next_action` |
| as_of | `2026-08-29T15:00:00Z` then `20:30:00Z` after public fixes |
| next_action | `send 4 cash-first Sweden IC applications` |
| pulses | `apply/sitting/cap`, stretch parked, citizenship, return-date |
| archive | 2–3 Jobanni, morning 10-mix |

After admit, **fix harness files** (Dashboard/Map/Career) so the next pulse does not re-litigate 2–3.

---

## Copy-paste checklist

1. Write `next_action` in one sentence.  
2. Pick mode: turn · both · thinking · harness.  
3. If workflow: set `as_of` first — then paths.  
4. Read `pulse.md` / `pulse_out`. Conflicts listed, not merged.  
5. Optional: upsert winners into `~/.local/share/pulse-memory/pulse.sqlite` (`kind=memory` only).
