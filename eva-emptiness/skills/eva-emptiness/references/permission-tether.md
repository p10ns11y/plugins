# EVA permission tether

Load when configuring Grok deny rules or reviewing hook behavior.

## Defaults under EVA

| Setting | Value |
|---------|-------|
| Permission mode | `ask` (never `always-approve`) |
| Plan mode | on until Act approved |
| `--max-turns` | set before long headless Score/Act |
| Subagents for Probe | prefer `explore` (no edits) |
| Simulate forks | worktree isolation |

## Deny patterns (config or hook)

Block or force-HITL:

- `git push`, `git push --force`, `git reset --hard`
- `rm -rf /`, recursive deletes outside the worktree
- Invoking `grok` / agents with `--always-approve` or `--yolo`
- Production deploy / secret-exfiltrating curl patterns (project-specific)

Plugin hook `bin/eva-tether-pretool.sh` implements a portable subset for `Bash` PreToolUse. Fail-open on hook crash — keep explicit `deny` JSON for real blocks.

## Card signal

On any permission deny or human reject of a dangerous tool: set `auth_horizon=hit` and transition to HITL Ask.
