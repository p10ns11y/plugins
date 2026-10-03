---
name: findings-first
version: 0.1.0
description: >
  Write findings to a file before pinging anyone. Review the buffer for
  patterns before spawning fixers. Supporting habit for events-over-timers.
  Talk ~49:00. House note: draft PRs before a findings file force a human
  pick-one question.
---

# findings-first

> **Load rule:** This file owns the buffer workflow. Pair with `events-over-timers` when triggers are noisy.

```text
FILE    : append-only findings document; one row per observation
PING    : only after the file exists; pointer to the file, not the raw dump
BUFFER  : lets a human or coordinator see the forest
PR      : no new pull request until findings for that theme exist
```

**Mission:** Collect before you fix. Notify with a pointer.

Lauren Tan described telling an agent to append banned patterns to a document and reviewing every few days (~49:00). On 3 Oct 2026, three draft pull requests opened before any findings file existed, which forced a "pick one" question to the human. That failure mode is why this habit exists.

Credit Lauren Tan and Matt Pocock.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| A watcher, linter, or scout found something worth tracking | Activate |
| Someone is about to ping a human with a raw log | Activate |
| Multiple draft PRs for the same theme with no shared findings file | Activate |
| One obvious fix already verified green | Skip |

Slash: `/findings-first`.

---

## Workflow

1. Choose or create the findings file for this theme. Path is stable and host-neutral.
2. Append one row per observation: what, where, when, evidence pointer. Do not open a fix PR yet.
3. If a human or coordinator must know, send a short pointer: path + count + oldest/newest row. Not the full dump.
4. On review cadence (human-chosen), read the file. Cluster rows. One pattern → one fix proposal; scattered one-offs → see `no-rule-one-off`.
5. Only after step 4: spawn fix work or open a pull request. One theme, one PR when possible.
6. When the cluster is resolved, mark rows done in the file or archive the slice.

### Neighbors

| Need | Load |
|------|------|
| Event triggers instead of cron polling | `events-over-timers` |
| Sparse tagged memory instead of transcript dumps | `pulse-memory` |
| Capture after review | `premflow` |

---

## Emit (required)

```markdown
## Findings-first
| Field | Value |
|-------|--------|
| **file** | path |
| **rows_added** | n |
| **pinged** | yes \| no |
| **pointer** | path or none |
| **clusters** | themes seen, or "too early" |
| **next** | review \| one fix PR \| wait |
```

---

## Done when

- Findings landed in a file before any human ping or fix PR
- A ping, if sent, is only a pointer
- No "pick one of three drafts" without a shared findings file

## Limitations

- Not a merge bot or review substitute.
- Does not replace `pulse-memory` admissions rules for long-lived memory.
