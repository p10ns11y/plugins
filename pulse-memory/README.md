# pulse-memory

**Pulse instead of dump.** Admissions filter for agent recall: sparse, dated, sourced snippets — not transcript floods. Resolves contradictions without averaging them into a fluent lie.

Essays (canonical prose):

- [Pulse instead of dump](https://captain.kingsparrow.space/focus/memory-issue)
- [Archive is not memory](https://captain.kingsparrow.space/focus/memory-issue/archive-not-memory)

Former skill name: `archive-not-memory` (redirect stub).

```text
  /pulse-memory                 turn mode — tag + admit in this chat
  /workflow pulse-memory        file cycle — needs as_of + paths
```

**Modes:** turn (skill) · `both` · `thinking` · `harness` · periodic (scheduler fills `as_of`).  
**thinking_path** = operator dump. **harness_path** = Dashboard / `next_action` / Card. **as_of** = ISO-8601; the workflow has no clock.

Worked copies: [skills/pulse-memory/references/usecases.md](skills/pulse-memory/references/usecases.md).

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install pulse-memory --trust
# or local:
grok plugin install ./pulse-memory --trust

# workflow is not auto-registered — copy into a discovery root:
ln -sfn "$(pwd)/pulse-memory/.grok/workflows/pulse-memory.rhai" ~/.grok/workflows/pulse-memory.rhai
```

Dev symlink:

```bash
mkdir -p ~/.grok/plugins ~/.grok/skills
ln -sfn "$(pwd)/pulse-memory" ~/.grok/plugins/pulse-memory
ln -sfn "$(pwd)/pulse-memory/skills/pulse-memory" ~/.grok/skills/pulse-memory
```

## Layout

```text
plugin.json
commands/pulse-memory.md
cursor/commands/pulse-memory.md
agents/pulse-memory.md
skills/pulse-memory/          # filter SoT
  SKILL.md
  references/admissions.md
  references/store.md         # SQLite archive vs memory
.grok/workflows/pulse-memory.rhai
test/
```

Plugins do not auto-register Rhai. Copy/symlink the workflow.

## Tests

```bash
./test/test-thin.sh
```

Workflow smoke: `/workflow pulse-memory` with fixture paths + `as_of`. Example args:

```json
{
  "mode": "both",
  "thinking_path": "pulse-memory/test/fixtures/thinking.md",
  "harness_path": "pulse-memory/test/fixtures/harness.md",
  "as_of": "2026-08-29T15:00:00Z",
  "next_action": "send 4 cash-first Sweden IC applications"
}
```

## Store

SQLite proposal (two layers: archive events vs admitted traces): [skills/pulse-memory/references/store.md](skills/pulse-memory/references/store.md). Pair with the `agent-local-db` skill for WAL / best-effort / `seen_count`.
