# Waste ledger template

Use placeholders only. Not legal advice. Sends, payments, deletes, merges, and publishes stay human-checked.

## Engagement meta

| Field | Fill in |
|---|---|
| Org | `OrgName` |
| Process under audit | `Process A` |
| Audit owner / sponsor | `Role` / `Role` |
| Start — ship date | `YYYY-MM-DD` — `YYYY-MM-DD` |
| Stop if evidence is thin | `YYYY-MM-DD` |
| Currency | `USD` or your unit |
| Scope / sample window | `1 process` / dates |

**Evidence bar:** a myth or maturity claim needs at least **two** of: time sample, money sample, frontline quote, failed-task autopsy. Record evidence IDs below.

## Flow rows (core)

| ID | Flow / agent step | Tool | Monthly cost | Time saved or lost (hrs/wk) | Waste type | Fix | Evidence | Disposition |
|---|---|---|---:|---:|---|---|---|---|
| F-01 | `Trigger → outcome` | `Tool` | `____` | `+ / − ____` | `Theater / rework / duplicate / orphan` | `____` | `E-__` | Keep / Kill / Test |
| F-02 | | | | | | | | |
| F-03 | | | | | | | | |

**Waste types (pick one per row):**

- **Theater:** tool or meeting that does not change output
- **Rework:** AI output wrong often enough that humans redo work
- **Duplicate:** two tools doing the same job
- **Orphan:** automation with no owner or no trigger

## Inventory (systems in the process)

| ID | System / tool | Job in process | Owner role | Cost / month | Rung: Ask / Do / Automate / Staff | Evidence | Disposition |
|---|---|---|---|---:|---|---|---|
| I-01 | | | | | | | |
| I-02 | | | | | | | |

**Rungs (one step at a time):** Ask → Do → Automate → Staff. Name the actual rung before any fix. Move a flow at most one rung per change.

## Time samples

| ID | Date / role | Step or interruption | Min / occurrence | Per week | Hrs / week | Source |
|---|---|---|---:|---:|---:|---|
| T-01 | | | | | | Observation / log / estimate |
| T-02 | | | | | | |

## Money samples

| ID | Period | Item | Cost / period | Alloc % to process | Avoidable? | Evidence |
|---|---|---|---:|---:|---|---|
| M-01 | | | | | Y / N / unclear | |
| M-02 | | | | | | |

## Failed-task autopsy

| ID | Date / task | Expected vs actual | Rework (min) | Root cause / fix | Evidence |
|---|---|---|---:|---|---|
| A-01 | | | | | |
| A-02 | | | | | |

## AI-theater meetings

| ID | Date / roles | Purpose | Minutes × people | Decision shipped? | Keep / shorten / kill | Evidence |
|---|---|---|---:|---|---|---|
| MT-01 | `YYYY-MM-DD / roles` | `____` | `____` | Yes / No | `____` | `E-__` |
| MT-02 | | | | | | |

## Totals (show arithmetic, not false precision)

- Time observed: `____` hrs/wk; rework: `____` hrs/wk; meeting load: `____` person-hrs/wk.
- Direct tool cost for this process: `____` / month; rework cost estimate: `____` / month; total measurable leakage: `____` / month.
- Evidence count: time `____`; money `____`; quotes `____`; autopsies `____`.
- Assumptions and missing samples: `____`.

## Kill / keep / test

| Decision | Item | Why (evidence IDs) | Owner role | Next check |
|---|---|---|---|---|
| KILL | | | | |
| KEEP | | | | |
| TEST | | | | |
