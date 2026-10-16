---
name: audit-allow-builds
description: >-
  Audits pnpm allowBuilds whitelist packages for supply-chain risk: resolved
  lockfile versions, new registry releases, lifecycle scripts, trust downgrades,
  and incident intel. Runs checks and install verification. Use when the user
  asks about allowBuilds, postinstall/build scripts, strictDepBuilds,
  approve-builds, or whether native-build deps were compromised.
---

# Audit allowBuilds packages

Port copy. Canonical file remains in https://github.com/p10ns11y/skills on master.

Workflow for packages explicitly allowed to run **lifecycle/build scripts** (`preinstall` / `install` / `postinstall`) under pnpm’s `allowBuilds` map. These are the highest-risk install surface after a maintainer hijack or typosquat.

Pair with [fix-dependency-security](../fix-dependency-security/SKILL.md) (audit, SFW, workspace policy) and [upgrade-packages](../upgrade-packages/SKILL.md) (bumps that may add new script runners).

## Why this is separate

| Control | What it blocks |
|---------|----------------|
| `pnpm audit` | Known CVEs in resolved versions |
| `minimumReleaseAge` / `blockExoticSubdeps` | Fresh or exotic installs |
| `trustPolicy: no-downgrade` | Weaker npm trust evidence vs prior release |
| **`allowBuilds`** | Which packages may **execute code at install time** |

A package can pass audit and still ship a malicious `postinstall` in a new patch. **Re-audit allowBuilds entries** after lockfile changes, incident news, or approving new build runners.

---

## Workflow checklist

```
- [ ] 1. Read allowBuilds (true entries only) from pnpm-workspace.yaml
- [ ] 2. Map lockfile versions: pnpm why <pkg> for each
- [ ] 3. Drift: stale whitelist vs tree; unapproved builds (install dry-run)
- [ ] 4. Advisories: pnpm audit (focus on allowBuilds names)
- [ ] 5. Scripts: npm view <pkg>@<version> scripts (current + latest)
- [ ] 6. Intel: Socket package score / StepSecurity write-ups if suspicious
- [ ] 7. Reinstall verify: sfw pnpm install --frozen-lockfile
- [ ] 8. Report: versions, parents, actions taken
```

---

## Step 1: Inventory the whitelist

In `pnpm-workspace.yaml`, list every `allowBuilds` key set to **`true`**. Ignore `false` denials.

Confirm guardrails stay on (do not disable without user approval):

- `strictDepBuilds: true`
- `dangerouslyAllowAllBuilds: false`
- `trustPolicy: no-downgrade` (when present)
- `minimumReleaseAge` / `minimumReleaseAgeStrict` (when present)

**Never** add `true` for convenience. Only packages that **require** native builds or documented postinstall (e.g. `sharp`, `esbuild`).

---

## Step 2: Resolved versions in this repo

For each allowed package name:

```bash
pnpm why <package>
```

Record:

- **Exact version(s)** in `pnpm-lock.yaml`
- **Importer chain** (direct dep vs transitive — e.g. `sharp` via `next` and `@huggingface/transformers`)

If `pnpm why` finds nothing but the name remains `true` in `allowBuilds`, the whitelist entry is **stale** — set to `false` or remove after user confirms nothing in the tree needs it (e.g. `esbuild` listed but not installed).

List all packages in the tree that still have ignored builds:

```bash
pnpm install --frozen-lockfile 2>&1 | rg -i "ignored build|ERR_PNPM_IGNORED_BUILDS|unreviewed"
```

With `strictDepBuilds`, install **fails** until every script runner is explicitly allowed or denied.

---

## Step 3: New versions vs locked versions

Check whether a newer release exists (supply-chain incidents often land as sudden patches):

```bash
pnpm outdated esbuild sharp onnxruntime-node protobufjs unrs-resolver
```

For each **locked** and **latest** version you care about, inspect lifecycle scripts on the registry:

```bash
npm view <package>@<locked-version> scripts version --json
npm view <package>@latest scripts version --json
```

Red flags (investigate before bumping or re-allowing):

- New or changed `postinstall` / `install` / `preinstall` on a package that previously had none
- Scripts that curl, download binaries from non-project domains, or read env secrets
- Version published within `minimumReleaseAge` window (install may be blocked — intentional)

When upgrading an allowBuilds package, follow [upgrade-packages](../upgrade-packages/SKILL.md) and **re-run this skill** on the new lockfile versions.

---

## Step 4: CVE / advisory pass

```bash
pnpm audit
```

Cross-check output paths for allowBuilds package names. Fix via overrides or parent bumps per [fix-dependency-security](../fix-dependency-security/SKILL.md) — do not only silence advisories.

---

## Step 5: Supply-chain intel (incidents & behavior)

Use when audit is clean but risk is elevated (news, maintainer takeover, unexpected install failure):

| Source | Use |
|--------|-----|
| [Socket package](https://docs.socket.dev/docs/socket-package) | `socket package deep pkg:npm/<name>@<version>` — install-script and behavior signals |
| [Socket Firewall (`sfw`)](https://docs.socket.dev/docs/socket-firewall-free) | Blocks confirmed malicious **fetches** on reinstall |
| [StepSecurity](https://docs.stepsecurity.io/) | npm incident timelines (typosquat, token leak) |
| `https://socket.dev/npm/package/<name>` | Quick human review |

Optional (if `@socketsecurity/cli` / `socket` is installed globally):

```bash
socket package deep pkg:npm/sharp@0.34.5
```

After known ecosystem incidents affecting an allowBuilds package:

```bash
pnpm store prune
sfw pnpm install --frozen-lockfile
```

---

## Step 6: Approving or denying builds

Interactive or explicit approval writes `pnpm-workspace.yaml`:

```bash
pnpm approve-builds              # interactive
pnpm approve-builds sharp !core-js   # allow sharp, deny core-js
pnpm approve-builds --all        # only with explicit user approval
```

**Before** setting a new entry to `true`:

1. Confirm the dependency is required (`pnpm why`)
2. Run Step 3 script inspection on the **exact** version to be locked
3. Prefer parent upgrade over expanding the whitelist

`pnpm add --allow-build=<pkg>` adds the same map entry — treat like `approve-builds`.

---

## Step 7: Validate

```bash
sfw pnpm install --frozen-lockfile
pnpm audit
pnpm type-check
pnpm lint
pnpm build    # if native modules (sharp, onnxruntime-node) changed
```

Summarize for the user:

| Package | Locked version | Parents | Latest on registry | Script delta | Action |
|---------|----------------|---------|-------------------|--------------|--------|
| … | … | … | … | none / changed | hold / bump / deny build |

---

## Project-specific notes

See [examples/README.md] for example `allowBuilds` whitelists (e.g. Next.js + ML native deps).

---

## Anti-patterns

- Setting `dangerouslyAllowAllBuilds: true` to silence `ERR_PNPM_IGNORED_BUILDS`
- Adding packages to `allowBuilds` without `pnpm why` and `npm view … scripts`
- Assuming `pnpm audit` clean means postinstall-safe
- Leaving `true` for packages no longer in the lockfile
- Approving `--all` pending builds without per-package review
- Skipping `sfw` reinstall after a published npm incident affecting an allowBuilds name

## Related skills

- [fix-dependency-security](../fix-dependency-security/SKILL.md) — audit, overrides, SFW, `minimumReleaseAge`, `trustPolicy`
- [audit-ide-dependencies](../audit-ide-dependencies/SKILL.md) — editor extensions/plugin caches (when IDE trees have their own lockfiles)
- [upgrade-packages](../upgrade-packages/SKILL.md) — version bumps; re-run this audit after Tier A/B/C upgrades

## References

- [pnpm allowBuilds](https://pnpm.io/settings#allowbuilds)
- [pnpm strictDepBuilds](https://pnpm.io/settings#strictdepbuilds)
- [pnpm approve-builds](https://pnpm.io/cli/approve-builds)
- [Mitigating supply chain attacks (pnpm)](https://pnpm.io/supply-chain-security)
- [Socket package CLI](https://docs.socket.dev/docs/socket-package)
