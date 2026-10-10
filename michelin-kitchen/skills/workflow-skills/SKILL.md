---
name: workflow-skills
version: 0.2.0
description: >
  Write skills as workflows, not command cheat sheets. Delete mechanical
  command lists when a script or model can infer them.
---

# workflow-skills

Older skills that are implementation details with exact commands: delete those commands. Focus on the workflow.

## When

| Signal | Action |
|--------|--------|
| A skill is mostly copy-paste commands | Activate |
| Mechanical steps repeat across agents | Activate; also `shared-scripts` |
| Skill already states workflow and verify only | Skip |

## Workflow

1. Read the skill as a human procedure. Mark pure mechanics.
2. Repeated mechanics → `shared-scripts` with a pointer.
3. Rewrite as steps: decide, verify, stop, emit.
4. Drop command dumps unless a flag is safety-critical.
5. Add a small Emit table.
6. If text duplicates installed pstack or `pstack-map`, link instead of copy.
7. A user-invoked skill orchestrates and does not call another user-invoked skill. A model-invoked skill holds the discipline. Load the other skill by the skill tool.

Upstream name: load `aihero-map`.

## Emit

```markdown
## Workflow skill
| Field | Value |
|-------|--------|
| **skill** | path |
| **removed** | commands or dumps deleted |
| **workflow_steps** | n |
| **script_pointers** | paths or none |
| **next** | one edit |
```
