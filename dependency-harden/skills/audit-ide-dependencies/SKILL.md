---
name: audit-ide-dependencies
description: >-
  Audits IDE tooling supply chain: Cursor/VS Code extensions, Cursor plugins,
  and bundled node_modules using pnpm/npm audit where lockfiles exist. Use when
  the user asks about Cursor plugins, extensions, MCP helpers, IDE malware, or
  whether editor dependencies were compromised.
---

# Audit IDE dependencies

Port copy. Canonical file remains in https://github.com/p10ns11y/skills on master.

Workflow to find **Node/npm dependency trees** shipped with or used by the editor (Cursor first; VS Code–compatible paths included). Most Cursor **plugins** in `plugins/cache` are skills/rules only; **extensions** and some cached plugin monorepos ship real `node_modules` and lockfiles — `pnpm audit` / `npm audit` apply there.

Pair with [fix-dependency-security](../fix-dependency-security/SKILL.md) (CVE fixes, SFW installs), [audit-allow-builds](../audit-allow-builds/SKILL.md) (postinstall allowlists when you `install` inside a plugin tree), and [upgrade-packages](../upgrade-packages/SKILL.md) (bumping plugin/extension deps).

## What audit can and cannot see

| Signal | `pnpm audit` / `npm audit` | Does not catch |
|--------|---------------------------|----------------|
| Known CVEs in locked versions | Yes | Fresh malware with no advisory yet |
| Transitive paths in lockfile | Yes | One-off malicious `postinstall` (use `npm view … scripts` + [audit-allow-builds](../audit-allow-builds/SKILL.md)) |
| Markdown-only plugins (skills, rules) | N/A — no lockfile | — |

**IDE trees are not the project repo.** Audits run in `~/.cursor/…` (or `$CURSOR_HOME`). Hardening in the repo’s `pnpm-workspace.yaml` does not apply there unless you install inside that tree.

---

## Workflow checklist

```
- [ ] 1. Set CURSOR_HOME (default ~/.cursor)
- [ ] 2. Discover audit targets (lockfiles + bundled node_modules)
- [ ] 3. Run pnpm audit or npm audit per target (exclude fixtures)
- [ ] 4. Triage: runtime extension vs dev-only plugin monorepo
- [ ] 5. Optional: npm view scripts on flagged packages; incident intel
- [ ] 6. Report + recommend disable/update/extension pin
- [ ] 7. Re-audit project repo separately (application root, not IDE extensions dir)
```

---

## Step 1: Paths (Cursor)

| Surface | Typical path | npm tree? |
|---------|--------------|-----------|
| **Extensions** | `$CURSOR_HOME/extensions/<publisher.name-version>/` | Often `node_modules/`; some have `package-lock.json` |
| **Plugin cache** | `$CURSOR_HOME/plugins/cache/<publisher>/<name>/<hash>/` | Varies: skills-only (no lockfile) vs full monorepo + `pnpm-lock.yaml` |
| **Plugin local** | `$CURSOR_HOME/plugins/local/` | User-installed plugins |
| **Project MCP descriptors** | `$CURSOR_HOME/projects/<id>/mcps/` | Usually JSON tool schemas, not install roots |
| **Repo agent skills** | `<repo>/.agents/skills/` | No npm deps — skip |

VS Code / VSCodium: same layout under `~/.vscode/extensions` or `~/.config/Code/User/…` if the user names another IDE.

```bash
export CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
```

---

## Step 2: Discover targets

**Lockfiles** (plugin/extension install roots — skip test fixtures and templates):

```bash
find "$CURSOR_HOME/plugins/cache" "$CURSOR_HOME/extensions" \
  \( -name pnpm-lock.yaml -o -name package-lock.json -o -name npm-shrinkwrap.json \) \
  2>/dev/null | rg -v '/test/|/tests/|/fixtures/|/templates/'
```

**Bundled `node_modules` without a root lockfile** (audit via nearest lockfile or note manual review):

```bash
find "$CURSOR_HOME/extensions" -maxdepth 2 -type d -name node_modules 2>/dev/null
```

**Plugins with no lockfile** (e.g. `svelte`, `linear`, `runlayer` — only `skills/` / `rules/`): no audit run; list as “non-npm surface”.

---

## Step 3: Run audit per target

For each discovered lockfile directory `DIR`:

```bash
cd "$DIR"
```

| Lockfile | Command |
|----------|---------|
| `pnpm-lock.yaml` | `pnpm audit` (use `pnpm install --frozen-lockfile` first only if audit errors on missing modules) |
| `package-lock.json` | `npm audit` |

Prefer **read-only** audit; do not `pnpm install` / `npm ci` in plugin caches unless the user wants deps installed. Large plugin monorepos (e.g. cached **shadcn** UI repo) may report many advisories in **dev/test** subtrees that never run inside the IDE — triage in Step 4.

**Project repo** (separate): from the user’s workspace root, run the same commands as [fix-dependency-security](../fix-dependency-security/SKILL.md) (`pnpm audit`, `sfw pnpm install`).

---

## Step 4: Triage findings

| Context | Action |
|---------|--------|
| **Extension** you rely on (Kilo, Python, Remote SSH) | Treat CVEs as user-facing; update extension in Cursor, or disable until patched |
| **Plugin cache monorepo** (tooling upstream clone) | Prefer “informational” unless you run `pnpm install` in that cache; consider clearing cache to refresh |
| **Critical / high on runtime path** | `pnpm why <pkg>` inside that `DIR`; check extension `package.json` `dependencies` |
| **No fix in audit** | Check StepSecurity / Socket blog for incident; do not assume clean |

Extensions without a lockfile: record extension id + version from `package.json`; security = publisher trust + update channel, not audit.

---

## Step 5: Beyond CVE audit (optional)

When audit is clean but an IDE package was in the news, or has install scripts:

```bash
npm view <package>@<version> scripts version --json
```

Install or refresh plugin deps only with SFW:

```bash
sfw pnpm install    # inside plugin dir with pnpm-lock.yaml
sfw npm ci           # inside extension dir with package-lock.json
```

Re-run [audit-allow-builds](../audit-allow-builds/SKILL.md) if you maintain `allowBuilds` in a plugin’s `pnpm-workspace.yaml`.

---

## Step 6: Report template

| Target | Path | Tool | CVEs (H/M/L) | Runtime risk | Action |
|--------|------|------|--------------|--------------|--------|
| e.g. `rust-analyzer` | `extensions/…` | npm audit | … | Extension runtime | Update extension |
| e.g. `shadcn` cache | `plugins/cache/…` | pnpm audit | … | Low (cache only) | Ignore / prune cache |
| `svelte` plugin | skills only | — | — | N/A | None |

Also state **project repo** audit result if run in the same session.

---

## Step 7: Remediation (user-facing)

1. **Cursor → Extensions**: update or disable affected extension.
2. **Cursor → Plugins**: remove unused plugins; re-add to pull a fresh cache hash.
3. **Clear stale cache** (optional): remove specific `plugins/cache/.../<hash>/` dir after disabling the plugin.
4. **Do not** copy vulnerable plugin `node_modules` into project repos.
5. Re-run this skill after Cursor updates or new plugin installs.

---

## Anti-patterns

- Assuming the application repo's `pnpm audit` covers Cursor extensions
- Running `pnpm install` in every plugin cache “to fix” audit noise without user approval
- Auditing `test/fixtures/**` lockfiles inside plugin monorepos as if they were IDE runtime
- Treating MCP JSON descriptors under `projects/*/mcps/` as npm packages
- Ignoring extensions with bundled `node_modules` but no lockfile (no audit possible — use publisher/version review)

## Related skills

- [project-editor-profile] — per-repo extension recommendations and unwanted list to limit editor attack surface
- [fix-dependency-security](../fix-dependency-security/SKILL.md) — project repo CVEs, SFW, `pnpm-workspace.yaml` policy
- [audit-allow-builds](../audit-allow-builds/SKILL.md) — lifecycle scripts when installing in a plugin tree
- [upgrade-packages](../upgrade-packages/SKILL.md) — upgrading deps in repos you control (not Cursor cache)

## References

- [pnpm audit](https://pnpm.io/cli/audit)
- [npm audit](https://docs.npmjs.com/cli/v10/commands/npm-audit)
- [Cursor plugins](https://cursor.com/docs/plugins) (discovery UI)
- [pnpm supply-chain security](https://pnpm.io/supply-chain-security)
