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

## Deny / Ask patterns (config or hook)

| Pattern | Cursor `eva-tether-shell.sh` | Grok `eva-tether-pretool.sh` |
|---------|------------------------------|------------------------------|
| `git push` (ordinary) | `permission: ask` (HITL) | `decision: deny` (force HITL — Grok has no ask JSON) |
| `git push --force` / `-f` | `deny` | `deny` |
| `git reset --hard` | `deny` | `deny` |
| `rm -rf /` (root) | `deny` | `deny` |
| `--always-approve` / `--yolo` | `deny` | `deny` |

Also project-specific: production deploy / secret-exfiltrating curl patterns.

Ordinary `git push` must not hard-deny forever — after explicit human approval the push should proceed. Force-push stays deny.

Plugin hook `bin/eva-tether-pretool.sh` implements a portable subset for `Bash` PreToolUse. Fail-open on hook crash — keep explicit `deny` JSON for real blocks.

## Card signal

On any permission deny or human reject of a dangerous tool: set `auth_horizon=hit` and transition to HITL Ask.
