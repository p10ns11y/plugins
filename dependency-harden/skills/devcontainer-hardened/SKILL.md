---
name: devcontainer-hardened
description: >-
  Generates minimal, security-first .devcontainer configs (devcontainer.json,
  optional Dockerfile) with pinned digests, non-root user, cap drops, and small
  blast radius. Use when the user asks for devcontainer, Dev Containers,
  Codespaces, remote development in Docker, or hardened containerized dev setup.
---

# Hardened devcontainer generator

Port copy. Canonical file remains in https://github.com/p10ns11y/skills on master.

Produce **small, explicit** Dev Container configs that prioritize **supply-chain safety** and **failure isolation** — not a kitchen-sink image.

Pair with [fix-dependency-security](../fix-dependency-security/SKILL.md) (pnpm policy, `sfw` installs) and [project-editor-profile](../project-editor-profile/SKILL.md) (`.editor` extension allowlist).

## Design principles (less is more)

1. **One job** — dev + build + lint + type-check in-container. E2E and host-only browsers stay **optional** and **off by default**.
2. **Pinned base** — image reference includes **digest** (`image@sha256:…`); re-pin deliberately, not on every edit.
3. **Non-root** — `remoteUser` / `containerUser` is not `root`; no `--privileged`.
4. **Minimal capabilities** — `runArgs`: `--cap-drop=ALL`, `--security-opt=no-new-privileges:true` when the host supports it.
5. **No secret sprawl** — no API keys, tokens, or `.env` copies in `devcontainer.json`; use Codespaces/VS Code secret stores if needed later.
6. **No Docker-in-Docker by default** — do not mount `docker.sock` unless the user explicitly needs it (huge blast radius).
7. **Frozen installs** — `postCreateCommand` uses `pnpm install --frozen-lockfile` (or `sfw pnpm install --frozen-lockfile` when SFW is available in the image).
8. **Extension allowlist** — only extensions that match the repo stack (read `.editor/profile.json` or `package.json`); never “install all recommended marketplace packs”.
9. **Explicit ports** — `forwardPorts` lists only ports the app actually uses (e.g. `3000`).
10. **Recoverable breaks** — prefer **devcontainer Features** over custom Dockerfile layers; if Dockerfile is required, keep it &lt; 15 lines and document why.

## Blast-radius map

| Choice | If it breaks later | Mitigation |
|--------|-------------------|------------|
| Pinned digest image | Rebuild fails when digest removed | Bump digest in one commit; test build |
| `postCreateCommand` only | Bad command blocks all devs | Keep one line; no chained curl scripts |
| Devcontainer Features | Feature repo moves/breaks | Use at most 1–2 features; pin feature version |
| Custom Dockerfile | Drift from upstream patches | Avoid unless base image cannot run pnpm/Node |
| E2E in container | Playwright/browser mismatch | Default **skip**; document host Brave path |
| `lifecycleScripts` | Arbitrary code on every open | Avoid `postStartCommand` unless required |

---

## Workflow checklist

```
- [ ] 1. Read stack: package.json, packageManager, pnpm-workspace.yaml, .editor/profile.json
- [ ] 2. Choose profile: default (Node+pnpm) | +playwright | +bun (only if user needs PDF script in-container)
- [ ] 3. Resolve `<NODE_MAJOR>` ([Step 1](#step-1-resolve-node-major)) — then pick **official** `node:<NODE_MAJOR>-bookworm-slim@sha256:…` (not `mcr.microsoft.com/devcontainers/*`)
- [ ] 4. Write .devcontainer/devcontainer.json (minimal keys only)
- [ ] 5. Add Dockerfile only if base cannot satisfy Node/pnpm/corepack
- [ ] 6. Align customizations.extensions with profile.json recommend (≤4 extensions)
- [ ] 7. Document intentional omissions in .devcontainer/README.md (1 short paragraph)
- [ ] 8. Validate: devcontainer build (or codespaces prebuild) + pnpm type-check && pnpm lint
```

---

## Step 1: Resolve Node major

**Always resolve when applying this skill** — do not copy `22`, `24`, or other majors from examples, old commits, or `@types/node` (types often lead the runtime).

### Priority

| Order | Source | How |
|-------|--------|-----|
| 1 | `package.json` → `engines.node` | Parse semver range; use the major the repo declares |
| 2 | Version pin files | `.nvmrc`, `.node-version`, `.tool-versions` (`nodejs …`) if present |
| 3 | **Current Node.js LTS** | Run [scripts/resolve-node-lts-major.mjs](scripts/resolve-node-lts-major.mjs) (or the one-liner below) at apply time |
| 4 | Weak hint only | `@types/node` major in `package.json` — confirm against (1–3); never treat types alone as runtime |

### LTS lookup (apply time)

```bash
node .agents/skills/devcontainer-hardened/scripts/resolve-node-lts-major.mjs
# prints major only, e.g. 24
```

Fallback (no script path):

```bash
node -e "fetch('https://nodejs.org/dist/index.json').then(r=>r.json()).then(rs=>{const l=rs.filter(x=>x.lts).sort((a,b)=>b.date.localeCompare(a.date))[0];process.stdout.write(l.version.replace(/^v/,'').split('.')[0])})"
```

Record the chosen major in `ARG NODE_VERSION` / `build.args.NODE_VERSION` and in `.devcontainer/README.md` (one line: major + LTS codename from the index entry).

### Detect stack (other signals)

| Signal | Config impact |
|--------|----------------|
| `packageManager`: `pnpm@…` | `corepack enable` + `corepack prepare pnpm@<version> --activate` in `postCreateCommand` |
| `pnpm-lock.yaml` + `verifyDepsBeforeRun` | Always `--frozen-lockfile` on install |
| `biome.json` | Recommend `biomejs.biome` only — not ESLint/Prettier |
| `@playwright/test` | **Do not** `playwright install chromium` by default when E2E uses a **host browser**; document host workflow in `.devcontainer/README.md` |
| `bun` in scripts (`generate-pdf`) | Optional `bun` feature; default **omit** (run PDF on host CI) |
| `pnpm-workspace.yaml` hardening | Mention in README: install must respect `allowBuilds` / `strictDepBuilds` |

---

## Step 2: Minimal `devcontainer.json` skeleton

Only include keys you need. Prefer this shape:

```json
{
  "name": "<repo>",
  "build": {
    "dockerfile": "Dockerfile",
    "context": "..",
    "args": { "NODE_VERSION": "<NODE_MAJOR>" }
  },
  "remoteUser": "node",
  "containerUser": "node",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "forwardPorts": [3000],
  "portsAttributes": {
    "3000": { "label": "Next.js dev", "onAutoForward": "notify" }
  },
  "postCreateCommand": "pnpm install --frozen-lockfile",
  "customizations": {
    "vscode": {
      "extensions": ["biomejs.biome", "bradlc.vscode-tailwindcss"]
    }
  },
  "remoteEnv": {
    "CI": "true",
    "COREPACK_ENABLE_DOWNLOAD_PROMPT": "0"
  },
  "runArgs": ["--cap-drop=ALL", "--security-opt=no-new-privileges:true"]
}
```

**Prefer `build` + slim Dockerfile** over prebuilt devcontainer images — fewer layers, smaller trust boundary.

Optional image-only setup (no Dockerfile) — still official Node slim, digest-pinned:

```json
"image": "node:<NODE_MAJOR>-bookworm-slim@sha256:<PINNED_DIGEST>"
```

Replace `<NODE_MAJOR>` per [Step 1](#step-1-resolve-node-major), then pin `<PINNED_DIGEST>`:

```bash
docker pull node:<NODE_MAJOR>-bookworm-slim
docker inspect --format='{{index .RepoDigests 0}}' node:<NODE_MAJOR>-bookworm-slim
```

Never use `mcr.microsoft.com/devcontainers/*` unless the user explicitly requires a Feature from that ecosystem. Never leave tags unpinned in committed config.

---

## Step 3: Dockerfile (only when necessary)

Rules:

- `FROM` — **`node:<ver>-bookworm-slim@sha256:…`** (Docker Official Image only)
- One `RUN` as root: OS deps (`ca-certificates`, `git`) + `corepack enable` + `corepack prepare pnpm@<version> --activate` (node cannot symlink into `/usr/local/bin`)
- Then `USER node`
- No `curl | sh`, no `npm i -g` except **corepack** / **pnpm** via corepack
- Do not `COPY .env` or secrets

Example minimal Dockerfile (repo root context, file at `.devcontainer/Dockerfile`):

```dockerfile
ARG NODE_VERSION=<NODE_MAJOR>
FROM node:${NODE_VERSION}-bookworm-slim@sha256:<PINNED_DIGEST>
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates git \
  && rm -rf /var/lib/apt/lists/*
USER node
```

---

## Step 4: What NOT to add (security)

| Avoid | Why |
|-------|-----|
| `"features": { "ghcr.io/…": "latest" }` | Unpinned third-party install scripts |
| `mounts` to `docker.sock`, `~/.ssh`, `~/.aws` | Host compromise path |
| `"privileged": true` / `--privileged` | Full host kernel exposure |
| `postStartCommand` / `updateContentCommand` with network fetches | Repeat supply-chain risk |
| Global `npm install -g` toolchains | Unpinned binaries |
| Installing Playwright browsers when project uses host browser E2E | Conflicts with host workflow; image bloat |
| Copying full `.cursor` plugin caches | Shadow tooling, huge context |
| `remoteUser: "root"` | Writable system inside container |

---

## Step 5: Optional capabilities (explicit opt-in)

Add only when the user requests:

| Need | Controlled addition |
|------|---------------------|
| E2E in Codespaces | Separate profile `devcontainer.e2e.json` or `hostRequirements`; document Brave unavailable → skip or use headless Chromium **only inside CI** with approval |
| PDF `generate-pdf` in container | `ghcr.io/devcontainers/features/node:1` + `common-utils` with `bun` feature — pin feature version |
| Git signing | Host-side or dedicated secret; not baked into image |
| SFW in container | Install `sfw` only if Socket documents container install; else keep SFW on host/CI |

---

## Step 6: Repo documentation

Create **`.devcontainer/README.md`** (short):

- Purpose of the config
- Commands: `pnpm dev`, `pnpm lint`, `pnpm type-check`
- What is **not** supported in-container (e.g. Brave E2E)
- How to refresh image digest
- Link to `pnpm-workspace.yaml` supply-chain policy

---

## Cursor: Anysphere Dev Containers (not Microsoft)

Cursor ships **`anysphere.remote-containers`** (“Dev Containers” by Anysphere). **Do not** use `ms-vscode-remote.remote-containers` in Cursor — it is unsupported and can break attach/build.

| Requirement | Action |
|-------------|--------|
| Host extension | `anysphere.remote-containers` (keep updated, ≥ 1.0.21 for `portsAttributes`) |
| Open command | **Dev Containers: Reopen in Container** |
| Port blast radius | `forwardPorts` explicit list + `"otherPortsAttributes": { "onAutoForward": "ignore" }` |
| Memory leaks (forum reports) | In `customizations.vscode.settings`: `"remote.restoreForwardedPorts": false`, `"remote.autoForwardPortsSource": "output"` |
| Workspace recommend | Add `anysphere.remote-containers` to `.vscode/extensions.json`; mark MS extension **unwanted** |

`customizations.vscode` in `devcontainer.json` still applies inside the container (Biome, TypeScript SDK, remote port settings copied per Anysphere 1.0.21+).

Document Cursor steps in `.devcontainer/README.md`.

---

## Step 7: Example starter configs

Copy and adapt from [examples/devcontainers/](../examples/devcontainers/) (see [examples/README.md](../examples/README.md) for provenance):

- [nextjs-portfolio.devcontainer.json](../examples/devcontainers/nextjs-portfolio.devcontainer.json)
- [nextjs-portfolio.Dockerfile](../examples/devcontainers/nextjs-portfolio.Dockerfile)

- **Node major:** run [scripts/resolve-node-lts-major.mjs](scripts/resolve-node-lts-major.mjs) unless `engines.node` / `.nvmrc` already pins the repo
- Extensions: mirror `.editor/profile.json` ([project-editor-profile](../project-editor-profile/SKILL.md))
- `postCreateCommand`: corepack + pnpm from `packageManager` + `pnpm install --frozen-lockfile`
- No Playwright browser download in `postCreateCommand` when using host-browser E2E

---

## Validation

```bash
# After config is written (host with Dev Containers CLI or CI)
pnpm install --frozen-lockfile
pnpm type-check
pnpm lint
# E2E: run on host with Brave Beta, not required inside container
```

---

## Anti-patterns

- Generating compose stacks with sidecar databases “for convenience” when the app has none
- Duplicating full CI in `postCreateCommand`
- Replacing project `pnpm-workspace.yaml` policy to “make install work” inside container
- Unpinned `features` with `latest` version strings
