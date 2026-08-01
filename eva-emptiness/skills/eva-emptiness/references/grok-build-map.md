# Grok Build ↔ EVA map

Load **only if** wiring a skeleton step to a concrete Grok Build feature. Official SoT: [docs.x.ai/build](https://docs.x.ai/build/overview).

| Skeleton | Grok feature | Notes |
|----------|--------------|-------|
| Prior | `/remember`, `/memory`, `/dream`, AGENTS.md, `/effort` high | Strong priors; consolidate without panic-forgetting |
| Notice IDK | `/plan`, clarifying Q&A | Plan mode gates edits until approve |
| Probe | `explore` subagents; one Q&A | Cheap; not doom-scroll |
| Simulate | `/fork --worktree`, `grok -w`, plugin agents `prior-*` | Prior-diverse forks; isolation=worktree |
| Score | Fresh session / review Role; `grok -p … --output-format json --max-turns N` | ⊥ implementer transcript |
| Act | Leave plan after approve; diffs | Claim-via-critical-path |
| Ask | Plan `a/s/c/q`; `permission_mode=ask` | Auth event horizon |
| Tether | `--max-turns`, plugin PreToolUse hook, `/rewind` | Bound surprise; deny trauma bash |
| Capture | `/skillify` successful EVA | Compounds process |

**Refuse under EVA:** `--always-approve`, `--yolo`, `permission_mode=always-approve`. Plan mode does **not** gate bash writes — tether hook + deny rules cover destructive shell.

**Not official SoT:** third-party “Arena Mode.” Prefer `/fork --worktree` + blind Score (RDM).
