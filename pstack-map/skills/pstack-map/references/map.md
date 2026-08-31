# Playbook map

Expand only to pick a row. Bodies live in installed **pstack** (`skills/poteto-mode/playbooks/`) or the house skill named here.

Credit: playbook names from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).

| Playbook | pstack if installed | House fallback | Skip on Grok when |
|----------|---------------------|----------------|-------------------|
| investigation | `/how` `/why` + investigation.md | how · why · structured-repo-explore | — |
| bug-fix | bug-fix.md | reproduce; fix; VERIFY real cmds | — |
| perf-issue | perf-issue.md | measure baseline; then change | no metric |
| hillclimb | hillclimb.md | one metric; one commit per win | — |
| runtime-forensics | runtime-forensics.md | instrument live; diagnosis first | — |
| trace-forensics | trace-forensics.md | read the artifact; diagnosis first | no trace file |
| feature | feature.md | named data shape; CG Inner ≤7 | — |
| refactoring | refactoring.md | behavior-preserving; smallest diff | — |
| prototype | prototype.md | throwaway; observe; do not ship | — |
| visual-parity | visual-parity.md | browser/screenshot verify | no UI |
| authoring-a-skill | authoring-a-skill.md | portable-skill-author | — |
| eval | eval.md | blinded before/after | — |
| babysit | babysit.md | pr-babysit | — |
| shipping | shipping.md | tidy-commit-push | Graphite MWR / auto-land |
| autonomous-run | autonomous-run.md | CG budgets | “until morning” without HITL |
| orchestrate | orchestrate.md | agent-orchestrator full | — |
| autopilot-full | autopilot-full.md | one owner per PR; human merge | auto-merge |
| autopilot-stack | autopilot-stack.md | linear branches; human land | Graphite-only land |
| session-pickup | session-pickup.md | orchestrator resume (gap only) | — |
| pause-safely | pause-safely.md | write Card + leftover; stop | — |
| multi-phase-plan | multi-phase-plan.md | CG PLAN; HITL if large | — |
| worktree-cleanup | worktree-cleanup.md | git-worktrees | — |
| figure-it-out | figure-it-out.md | CG PLAN + VERIFY | — |

## Skills (load, do not copy)

| pstack skill | House / note |
|--------------|----------------|
| unslop | load if installed; else short formal English |
| how / why | load if installed; else structured-repo-explore |
| architect | architecture-synthesis |
| arena / swarm | concurrent-cli-agents |
| interrogate | review · adversarial-audit |
| tdd | failing test first when cheap |
| typescript-best-practices | when editing `.ts`/`.tsx` |
| blast-radius | grep callers; run the proof |
| prove-it-works | VERIFY real cmds (adversarial-audit) |
| never-block-on-the-human | **override:** HITL on secrets/prod/irreversible/auth unknown |
| setup-pstack | optional; CG roles if no Cursor models |
| no-comments | strip narrating comments |
| technical-writing | README/PR/commit: short, factual |
| automate-me / make-bot-ui / benny | skip |

## Cursor-only (name, do not emulate)

- Graphite `merge-when-ready`
- `cursor-team-kit` `/deslop`, `control-cli`, `control-ui` (use unslop / browser verify)
- Slack **benny** automations
- Default Task models `gpt-5.6-sol-max` / `claude-fable-5-thinking-max` (host default unless setup-pstack wrote a rule)
