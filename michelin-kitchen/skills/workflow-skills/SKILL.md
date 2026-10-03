---
name: workflow-skills
version: 0.1.0
description: >
  Write skills as workflows (ordered steps and judgment), not as command
  cheat sheets. Delete mechanical command lists when a script or model can
  infer them. Talk ~62:00–65:30.
---

# workflow-skills

> **Load rule:** This file owns skill shape. Pair with `shared-scripts` when steps repeat mechanically.

```text
WORKFLOW : ordered steps, decisions, and verify — not a shell transcript
COMMANDS : move to scripts when identical every time
COMPACT  : skills should shrink as models improve
PROCESS  : encode how you think, not every flag
```

**Mission:** Teach the agent your process, not your terminal history.

Lauren Tan said older skills were "almost like implementation details" with exact script commands (~65:00). With stronger models, delete those parts and "really focus on the workflow" (~65:00–65:30) — a series of steps in your process.

Credit Lauren Tan and Matt Pocock.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| A skill is mostly copy-paste commands | Activate |
| New skill draft reads like a bash script | Activate |
| Mechanical steps repeat across agents | Activate; also `shared-scripts` |
| Skill already states workflow and verify only | Skip |

Slash: `/workflow-skills`.

---

## Workflow

1. Read the skill aloud as a human procedure. Circle every line that is pure mechanics.
2. For mechanical blocks that repeat, extract to `shared-scripts` and leave a pointer.
3. Rewrite remaining content as steps: what to decide, what to verify, when to stop, what to emit.
4. Remove imperative command dumps unless a flag is non-obvious and safety-critical.
5. Add an Emit block with a small table so hosts can scrape outcomes.
6. Re-read for length. If a section duplicates an installed playbook (pstack via Cursor, or `pstack-map` here), link instead of copy.

### Neighbors

| Need | Load |
|------|------|
| Deterministic repeated work | `shared-scripts` |
| Playbook map when pstack is installed | installed pstack, else `pstack-map` |
| Trust and verify layers | `trust-stack` |

---

## Emit (required)

```markdown
## Workflow skill
| Field | Value |
|-------|--------|
| **skill** | path |
| **removed** | what left (commands, dumps) |
| **workflow_steps** | n |
| **script_pointers** | paths or none |
| **next** | one edit |
```

---

## Done when

- The skill reads as a procedure, not a command list
- Repeated mechanics point at a script or upstream playbook
- An Emit table exists

## Limitations

- Does not install [pstack](https://github.com/cursor/plugins/tree/main/pstack) (Lauren Tan's Cursor plugin).
- Does not auto-shrink other people's skills without consent.
