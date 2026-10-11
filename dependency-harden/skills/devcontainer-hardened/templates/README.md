# Devcontainer templates

Starter configs live in [examples/devcontainers/](../../examples/devcontainers/) — copy into `.devcontainer/` when applying [SKILL.md](../SKILL.md).

| Example | Target |
|---------|--------|
| `nextjs-portfolio.devcontainer.json` | `.devcontainer/devcontainer.json` |
| `nextjs-portfolio.Dockerfile` | `.devcontainer/Dockerfile` |

Before commit:

1. Resolve `<NODE_MAJOR>` per [SKILL.md Step 1](../SKILL.md#step-1-resolve-node-major).
2. Pin `FROM node:<NODE_MAJOR>-bookworm-slim@sha256:…`.
3. Match `corepack prepare pnpm@…` to `package.json` → `packageManager`.
4. Run `pnpm install --frozen-lockfile` inside the built container.

See [examples/README.md](../../examples/README.md) for project provenance.
