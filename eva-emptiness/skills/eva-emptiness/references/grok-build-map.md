# Grok Build ↔ EVA map

Load **only if** wiring a skeleton step to a concrete Grok Build feature. Official SoT: [docs.x.ai/build](https://docs.x.ai/build/overview).

| Skeleton | Grok feature | Notes |
|----------|--------------|-------|
| Prior | `/remember`, `/memory`, `/dream`, AGENTS.md, `/effort` high | Strong priors; consolidate without panic-forgetting |
| Notice IDK | `/plan`, clarifying Q&A | Plan mode gates edits until approve |
| Probe | `explore` subagents; one Q&A | Cheap; not doom-scroll |
| Simulate | `/fork --worktree`, `grok -w`, plugin agents `prior-*` | Prior-diverse **pathways**; isolation=worktree |
| Score | Fresh session / review Role; `grok -p … --output-format json --max-turns N` | ⊥ implementer; include robust-satisficing + option-preserve |
| continue | Leave plan after approve; diffs | Claim-via-critical-path on `pathway_active` |
| switch | Re-enter Prior / CG re-ORIENT | New `pathway_active`; not silent Act |
| Ask | Plan `a/s/c/q`; `permission_mode=ask` | Auth event horizon |
| Tether | `--max-turns` / Rhai `max_turns`, plugin PreToolUse hook, `/rewind` | Bound surprise; deny trauma bash |
| Phase handoff | Compact prior `output` JSON into next prompt | No goal-only re-prompt; no full transcripts |
| Capture | `/skillify` successful EVA | Compounds process |
| Background EVA | `/workflow eva-emptiness` after `.rhai` in `.grok/workflows/` | Host `agent()` phases; `/workflows` dashboard |
| Suggest next | `/workflow multi-agent-delivery`, `context-ignite`, `/deep-research` | Skill names them; human launches |

**Workflow discovery (official):** project `<repo>/.grok/workflows/*.rhai`, user `~/.grok/workflows/*.rhai`. Filename ≈ `meta.name`. Built-in > project > user on name clash. Disable: `[workflows] enabled=false` or `GROK_WORKFLOWS=0`.

**Refuse under EVA:** `--always-approve`, `--yolo`, `permission_mode=always-approve`. Plan mode does **not** gate bash writes — tether hook + deny rules cover destructive shell.

**Not official SoT:** third-party “Arena Mode.” Prefer `/fork --worktree` + blind Score (RDM).
