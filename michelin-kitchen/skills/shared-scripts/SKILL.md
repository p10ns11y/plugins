---
name: shared-scripts
version: 0.1.0
description: >
  When a job repeats across agents, write one deterministic script with JSON
  output and an index entry instead of each agent rebuilding it. Use for
  repeated checks, verification glue, or mechanical transforms. Talk ~22:00.
---

# shared-scripts

> **Load rule:** This file owns the workflow. Example layout: [examples/posting-check/README.md](../../examples/posting-check/README.md). Do not paste the whole example into context.

```text
DETERMINISTIC : no LLM in the hot path; stdlib or thin glue only
JSON          : one object per item; stable field names
INDEX         : one line in a scripts index so the next agent finds it
JUDGMENT      : stays in the skill; the script does the mechanical part
```

**Mission:** Extract what every agent was redoing by hand into one script they can call.

Credit Lauren Tan and Matt Pocock. Talk ~22:00–25:00.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| Two or more agents wrote similar glue for the same check | Activate |
| A skill keeps re-explaining how to call an API mechanically | Activate |
| One-off edit with no repeat expected | Skip |

Slash: `/shared-scripts`.

---

## Workflow

1. Name the repeated job in one sentence. What must every agent get the same answer for?
2. List what the last two agents did differently. That diff is the script spec.
3. Write the script: deterministic, JSON to stdout, exit codes documented. No LLM inside.
4. Add an index entry (path, one-line purpose, example invocation). Host-neutral paths only.
5. Shrink the skill: keep judgment and when-to-run; delete the rediscovered commands.
6. Run the script once from a clean shell. Attach sample output or point to a checked fixture.

### Neighbors

| Need | Load |
|------|------|
| Where a finding should land before anyone is pinged | `findings-first` |
| Verification layers for an invariant | `trust-stack` |
| Playbook steps when pstack is installed | installed pstack, else `pstack-map` |

---

## Emit (required)

```markdown
## Shared script
| Field | Value |
|-------|--------|
| **job** | |
| **script** | path |
| **output** | JSON shape |
| **index** | where listed |
| **skill_delta** | what to delete from the skill |
| **next** | one verification run |
```

---

## Done when

- The script runs without an LLM
- JSON fields are stable
- The index entry exists
- The skill no longer asks agents to reinvent the glue

## Limitations

- Not a place for judgment calls, novel refactors, or one-off fixes.
- Does not replace `trust-stack` checks; it carries deterministic verify steps.
