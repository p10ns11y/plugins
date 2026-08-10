# EVA permission tether

Load when configuring Grok deny rules or reviewing hook behavior.

## Runtime order (secure path first)

| Priority | Implementation | When |
|----------|----------------|------|
| 1 | **C binary** `bin/eva-tether` | Present + executable (compile via `/eva-tether-init --yes`) |
| 2 | **Shell fallback** `bin/eva-tether-shell.inc` | No C compiler / binary missing |
| Shell pref | **zsh** first when available; bash and other POSIX shells must work | Entry hooks re-exec zsh once |

Entry hooks (never call raw C yourself from agents):

| Surface | Entry | Mode |
|---------|-------|------|
| Grok PreToolUse | `bin/eva-tether-pretool.sh` | `--mode=grok` |
| Cursor beforeShell | `cursor/hooks/eva-tether-shell.sh` | `--mode=cursor` |

Compile (consent only): `/eva-tether-init --yes` → agent-internal `bin/eva-tether-build --yes`.  
Sources: `c/eva_tether.c`, `c/main.c`. Kept binary: `bin/eva-tether`.

## Defaults under EVA

| Setting | Value |
|---------|-------|
| Permission mode | `ask` (never `always-approve`) |
| Plan mode | on until Act approved |
| `--max-turns` | set before long headless Score/Act |
| Subagents for Probe | prefer `explore` (no edits) |
| Simulate forks | worktree isolation |

## Deny / Ask patterns (config or hook)

| Pattern | Cursor hook | Grok hook |
|---------|-------------|-----------|
| `git push` (ordinary) | `permission: ask` (HITL) | `decision: deny` (force HITL — Grok has no ask JSON) |
| `git push --force` / `-f` / `--force-with-lease` | `deny` | `deny` |
| `git reset --hard` | `deny` | `deny` |
| `rm -rf /` (root) | `deny` | `deny` |
| `--always-approve` / `--yolo` | `deny` | `deny` |

Also project-specific: production deploy / secret-exfiltrating curl patterns.

Ordinary `git push` must not hard-deny forever — after explicit human approval the push should proceed. Force-push stays deny.

## Security properties

- **No eval** in shell path; fixed reason strings only in emit paths.
- **Bounded C stdin** (`EVA_TETHER_INPUT_MAX_BYTES`); fail-open on I/O/parse crash (Grok contract).
- **Word-boundary scanners** for `git` / `push` / `rm` (not naive substring alone for push).
- Shell path: quote expansions; optional `jq` only for nested JSON field extract.
- Consent-gated compile: never write `bin/eva-tether` without `/eva-tether-init --yes`.

Fail-open on hook crash — keep explicit `deny` / `ask` JSON for real blocks.

## Card signal

On any permission deny or human reject of a dangerous tool: set `auth_horizon=hit` and transition to HITL Ask.
