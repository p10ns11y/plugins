# AGENTS.md — plugins (p10ns11y/plugins)

Grok Build / agent **marketplace plugins** — installable skill + command + agent + hook bundles.

**Owner:** product plugins in this repo (`mission-map`, `uncertainty-laws`, `pstack-map`, `layout-content-view`, `pulse-memory`, `odysseus-navigator`, `eva-emptiness`, `arch-machine`, `premflow`, `intelliarch`, `split-machine`, `trust-stack`).  
**Catalog:** [README.md](README.md) · [.grok-plugin/marketplace.json](.grok-plugin/marketplace.json)

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install <name> --trust
```

## Bend

From `trust-stack/bend/`:

When using Bend:
- run `bend guide` to learn it
- use `LAWS.bend` to keep important rules
- run `bend PROOF.bend` before committing
- parallelize the code whenever possible

Bend 2 is a new language. Bend 1 and HVM do not carry over. `All terms check.` is the shape layer only. The test, the review, and a person on `guide` still count.

Write a law for a finite claim over `Nat`, `U32`, or `Data` that you can prove by hand. Nothing is inferred. There are no tactics, no `if`, and no type classes. Recursion must shrink. A parallel split has to be balanced. Do not put a law on `F32`. Do not treat the JavaScript target as parallel, and do not `@unsafe` your way around a failed proof.

The checker is young, mostly un-audited, and its Lean model does not match `bend.ts`. A proved law can still be wrong. Report the Bend bug. Keep the other layers.

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
