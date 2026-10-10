---
name: shared-scripts
version: 0.2.0
description: >
  When a job repeats across agents, extract deterministic glue into one script.
  Keep the CLI inside the skill. JSON stdout, a scripts index, and no LLM in
  the hot path.
---

# shared-scripts

When agents keep rebuilding verification glue, encode the deterministic parts in a CLI inside the skill. Use JSON stdout, a separate scripts index, and no LLM in the checker.

Example shape: a job-posting open/closed checker — deterministic script, one JSON object per URL, one index line.

## When

| Signal | Action |
|--------|--------|
| Two or more agents wrote similar glue | Activate |
| A skill re-explains the same API call | Activate |
| One-off with no repeat expected | Skip |
| A whole spec is a task graph of tickets | Activate. One deterministic script runs each ready ticket. Parallel tickets use separate worktrees. |

## Workflow

1. Name the repeated job. What must every agent answer the same way?
2. Diff what the last two agents did. That is the script spec.
3. Write deterministic glue. JSON to stdout, documented exit codes, no LLM inside.
4. Add a scripts-index entry: path, purpose, example call.
5. Shrink the skill: keep judgment and when-to-run; delete rediscovered commands.
6. Run once from a clean shell; keep sample output or a fixture.
7. For a task graph, the script is the runner. An agent that walks the frontier is only the stand-in until that script exists. Load `git-worktrees` for the parallel checkouts.

Load `findings-first` when observations should land in a file first. Load `trust-stack` when the script enforces an invariant.

## Emit

```markdown
## Shared script
| Field | Value |
|-------|--------|
| **job** | |
| **script** | path |
| **output** | JSON shape |
| **index** | where listed |
| **skill_delta** | what to delete |
| **next** | one verification run |
```
