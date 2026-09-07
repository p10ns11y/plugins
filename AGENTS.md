# AGENTS.md — plugins (p10ns11y/plugins)

Grok Build / agent **marketplace plugins** — installable skill + command + agent + hook bundles.

**Owner:** product plugins in this repo (`mission-map`, `pstack-map`, `layout-content-view`, `pulse-memory`, `odysseus-navigator`, `eva-emptiness`, `arch-machine`, `premflow`).  
**Catalog:** [README.md](README.md) · [.grok-plugin/marketplace.json](.grok-plugin/marketplace.json)

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install <name> --trust
```

## In scope

Work inside a plugin directory or shared repo docs. Each plugin owns its `README.md`, `skills/`, `commands/`, and optional `.grok/workflows/*.rhai` (copy/symlink into a Grok workflows root — plugins do not auto-register Rhai).

## Out of scope (do not touch from here)

- **collab-finder**, **packedbox**, **kingsparrow** — sibling apps; not this repo.
- **premflow CLI** lives at [thecuriousts/premflow](https://github.com/thecuriousts/premflow); this repo only ships the Grok plugin wrapper.

## Hard nos

1. **No secrets / PII** in commits, fixtures, or docs (tokens, emails, employer names, live hiring state).
2. **No thecuriousts CI burn** — do not open PRs or push churn to `thecuriousts/premflow` from plugin work here.
3. **No Reset** — no `git reset --hard`, no destructive history rewrite, no “reset and redo” that drops operator state without explicit consent.

## PRs

Use [.github/pull_request_template.md](.github/pull_request_template.md). Tick the harness you used (OpenCode · Grok Build · cursor-agent).
