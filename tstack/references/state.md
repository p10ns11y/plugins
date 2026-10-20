# Shared loop state

`tstack-state` is the write. SI owns that write. The model only drafts arguments. Harvest, pulse-memory, and mission-map stay loaded plugins. This reference does not copy a skill, command, or agent.

## Path

1. `TSTACK_STATE_DB` if set.
2. Else `PULSE_MEMORY_DB` if set.
3. Else `$XDG_DATA_HOME/tstack/state.sqlite`, or `~/.local/share/tstack/state.sqlite` when `XDG_DATA_HOME` is unset.

On startup the script sets `umask 077`, connects, then runs these two pragmas before `BEGIN`:

```sql
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
```

They are per connection and are not part of either migration. A missing parent of the database file is created here. Mode `0700` applies only to that directory, and only when this process created it. The database file is mode `0600`. Do not move or delete `~/.local/share/pulse-memory/pulse.sqlite`. Point `PULSE_MEMORY_DB` at that file to keep using it.

`init` applies each missing section of `scripts/schema.sql` in its own transaction, then inserts `schema_migrations`. Statements run with `execute`. A second `init` exits 0 and does not insert another version row. `init` prints `{"versions": [1, 2]}`.

`applied_at`, `maps.updated_at`, `blocks.started_at`, `blocks.closed_at`, `harvest_rows.ts`, `archive_events.ts`, and `conflicts.ts` from `pulse conflict` are UTC ISO-8601 from the script clock. `pulse admit --time` is the caller stamp for `time`, `first_seen`, and `last_seen`. A locked disagree stores that same stamp on `conflicts.ts`.

## Commands

Exit `0` ok, `2` usage, `3` rejected, `1` a broken migration. Each exit prints one JSON object.

```text
tstack-state init
tstack-state map put --id ID --g TEXT [--effort-cap N]
tstack-state stage put --map ID --id ID --class Do|Risk|Wait|Park|Done \
  --a N --m N --b N --label TEXT [--depends id,id] [--critical 0|1] [--next 0|1]
tstack-state next --map ID
tstack-state export-map --map ID
tstack-state apply-report --map ID --critical id,id [--next ID]
tstack-state block open --map ID --stage ID --energy high|mid|low [--plan TEXT] [--timeout-min 120]
tstack-state block beat --map ID
tstack-state block close --id N
tstack-state block close --map ID
tstack-state harvest add --map ID --stage ID --result TEXT --evidence TEXT [--key KEY]
tstack-state harvest list --map ID [--stage ID]
tstack-state ask admit --ask TEXT
tstack-state pulse archive --source TEXT --payload TEXT [--correlation TEXT]
tstack-state pulse admit --key TEXT --snippet TEXT --source TEXT --time TEXT \
  --status user-stated|tool-verified|inferred|unknown \
  --kind data|context|fact|memory [--lock open|locked]
tstack-state pulse list [--limit 8]
tstack-state pulse conflict --subject TEXT --left ID --right ID --resolution TEXT
tstack-state step start --map ID --stage ID --step NAME
tstack-state step beat --id N
tstack-state step end --id N --status ok|fail|abandoned [--note TEXT]
tstack-state resume [--map ID] [--timeout-min 120]
tstack-state effect check --key KEY
tstack-state effect record --key KEY --kind push|linear-comment|log-row|... [--ref TEXT]
tstack-state effect list [--kind KIND]
```

`next` prints `{"stage_id": "..."}` or `{"stage_id": null}`. It reads `next_do = 1` and does not scan `class`.

`block open` prints `{"id": N, "map_id": "...", "stage_id": "..."}`. It requires `class = Do`, an existing stage, and no other open block on that map. `--plan` stores the given text. Omitted `--plan` stores null. The script does not call premflow.

`block close` takes exactly one of `--id` or `--map`. `--map` closes the single open block on that map. No open row, or an unknown id, exits 3.

`map put` and `stage put` upsert. On insert, omitted `--depends` is `[]` and omitted flags are 0. On update, omitted `--depends`, `--critical`, and `--next` leave the stored values. `--a`, `--m`, `--b`, `--label`, and `--class` are required on every `stage put`. Setting `--next 1` sets `next_do = 0` on every stage of that map, then sets `next_do = 1` on the named stage, in one transaction.

Map ids and stage ids match `^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$` before insert. `depends_on` is a JSON array of those ids. Each id must already be a stage on that map, and must not be the stage being written. The script does not look for cycles.

`nat_key` is a different column. Length 1–200 after trim. Slashes are allowed. `@` is rejected. Do not put the stage-id pattern on `nat_key`.

`g`, `label`, `plan`, `result`, `evidence`, `snippet`, and `payload` are rejected when they contain `@`. A blank `g` is rejected. The error is `Ask: name a checkable arrival.` The stored arrival stays as it was, and the script does not export the map. There is no contact column and no email column. A stage without `a`, `m`, and `b` is refused. `stage put` has no deadline column. `harvest add` does not set `class` to Done. A `result` whose words include `money`, `health`, or `family` is rejected, and no row is written.

`ask admit` stores one ask. The same ask again exits 3 with `repeated ask` and does not insert another row.

`export-map` prints one object. Top-level keys are `g` and `stages`. Each stage has `id`, `a`, `m`, `b`, `depends_on` (a JSON array of strings), `class`, and `what` (from `label`). `effort_cap` stays in `maps` and is omitted. A stored `depends_on` that is not a JSON array exits 3. There is no `email` key and no `contact` key.

`apply-report`, in one transaction: set `critical = 0` and `next_do = 0` on every stage of the map, set `critical = 1` for each id in `--critical`, then set `next_do = 1` for `--next` when that flag is present. An unknown id exits 3 and rolls back. Omitted `--next` leaves every `next_do` at 0. `--critical` is a comma list with no spaces.

`pulse list` returns `kind = memory` and `superseded_by IS NULL`, newest `time` first, default limit 8.

`pulse admit` inserts `seen_count = 1`, `lock` from `--lock` or `open`, and null `verify_hash`, `prefetch_key`, and `superseded_by`. `first_seen` and `last_seen` equal `--time`. On the same `nat_key`, an open lock, or a locked lock with the same snippet, bumps `seen_count` and sets `last_seen` to the new `--time`. Snippet, status, kind, and lock stay as stored. A locked key with a different snippet keeps the old row, inserts `nat_key-2` then `nat_key-3`, skipping keys that exist, and inserts `conflicts`. That path exits 0. `conflicts.subject` is the original `nat_key`, `left_id` and `right_id` are the row ids, `resolution` is `not in the evidence`, and `ts` is the new `--time`. The script does not pick a winner.

`pulse conflict --left` and `--right` are `nat_key` values. A missing key exits 3. After every `pulse admit` or `pulse conflict`, on the same connection, before commit:

```sql
INSERT INTO memory_fts(memory_fts) VALUES('rebuild');
```

## Who reads and writes

| Table | mission-map | harvest | pulse-memory | tomato-loop |
|-------|-------------|---------|--------------|-------------|
| `maps` | write | read | read | read |
| `stages` | write | read | read | read |
| `blocks` | read | write close | read | write open |
| `harvest_rows` | read | write | read | read |
| `archive_events` | read | — | write | — |
| `memory_traces` | read | — | write | — |
| `memory_fts` | — | — | write (rebuild) | — |
| `conflicts` | read | — | write | — |

tomato-loop is the tstack skill that opens a block. It is not a fourth plugin.

## Graph stdout

`export-map` writes a temp file outside the repo. If `mission-map-graph` is on PATH, run `mission-map-graph <temp>` with no `--mermaid` and no `--compare`. The binary reads a file path. It does not read stdin.

On exit 0, take the line that starts with `critical=` and split the value on ` -> `. Ignore `critical_prob`. Take the line that starts with `next_do=` when it is present. `apply-report` writes those flags. If `next_do=` is absent, omit `--next`. Delete the temp file either way. If the binary is missing or exits non-zero, skip `apply-report` and keep the human-confirmed classes and the human-named next Do.

The graph CLI also prints `g=`, `path_te=`, `heading=`, `cos=`, and the Monte Carlo lines. Read `critical=` and `next_do=` only.

The graph CLI exits when a map has more than 32 stages. The SQLite file may hold more. Do not copy that limit into SQL. The graph CLI exits on a cycle, and the skill then skips `apply-report`.

## One loop turn

1. mission-map writes `map put` and `stage put` for the human-confirmed map, including `a`, `m`, and `b`. The human-named next Do is `--next 1` on that stage.
2. Export, run the graph CLI, and `apply-report` as in Graph stdout. A missing or failing binary keeps the human-confirmed classes and the human-named next Do.
3. tomato-loop reads `next` and runs `block open`, passing the plan text.
4. harvest runs `harvest add`, then `block close --map`. No evidence, no row.
5. pulse-memory reads `harvest list` for that row. It runs `pulse archive` always. It runs `pulse admit` only when its own admissions test passes. One admit.
6. mission-map reads `harvest list`, marks that stage Done with the same bands and label, reads `pulse list`, exports, applies the report, and reads `next`.

## Premflow

Optional. Detect it with `command -v premflow`. Use it for a timed block and for win / task-done only when it is found. The state script does not call it. `blocks.plan` stores the plan string the operator named, or null when `--plan` is omitted. Premflow's ledger stays a separate text store.

Public log rows stay out of the repo. There is no `LOG.md` in tstack. Append a public row only when the operator names a path. Money, health, and family figures stay out of that file and out of `label`, `result`, and `snippet`.

## Durable steps (migration 3)

Install: `tstack/scripts/install.sh [BIN_DIR]` links `tstack-state` and `tstack-pr-triage` into `~/.local/bin` and runs `init`.

- **Step journal.** `step start` writes a `running` row with `started_at` and `heartbeat_at`; `step end` sets `ended_at` and the status. Starting a step that is still `running` returns the same row with `resumed: true`, so a restart after a crash picks up the row instead of adding one. `step end` twice is a no-op.
- **Resume.** `resume` lists every step started and not ended, and every open block with `idle_min` and `stale` (idle at or past the timeout, default 120 min). Run it first in a session.
- **Stale blocks.** `block open` on a map whose open block is stale exits 3 with `stale open block` and the block id. Resume it (`block beat`) or close it. A live open block still exits 3 with `second open block`.
- **Effect keys.** Every side effect gets a key: chunk id, commit SHA and effect kind, e.g. `c22:1a2b3c4:linear-comment`. Check with `effect check` before the effect, do it, then `effect record`. A repeated key is a no-op. A crash between the effect and the record can still repeat that one effect, so the effect itself must be safe to retry where it can (append only if absent, edit the same comment).
- **Harvest keys.** `harvest add --key KEY` writes once per key; a repeat returns the first row with `duplicate: true`.

## Credits and prior art

**Credit.** [pi durable](https://www.npmjs.com/package/@earendil-works/pi-durable) (`@earendil-works/pi-durable`) and [@_alejandroao's tutorial](https://x.com/_alejandroao/status/2112112346462089276), for the explicit framing of per-step checkpoints, crash resume without a manual "continue", and the requirement that side effects be idempotent on retry.

**Prior art.** tstack already had a SQLite state store (maps, stages with a DAG, open/closed focus blocks, harvest rows). Ensembly already had crash-safe CRDT memory that dedupes re-appends on merge (`ensembly-memory` `crdt.rs`) and pulse import keyed so importing twice changes nothing. This change fills only a few gaps inspired by pi durable: a step journal with start/heartbeat/end, `resume` crash detection, idempotency-keyed effects, stale-block flagging, and PR age triage.
