# dependency-harden

Installable dependency hardening. The skills repo remains the canonical URL until a later issue switches `intelli-route`.

| Slash | Loads | Stops short of |
| --- | --- | --- |
| `/dependency-harden` | `fix-dependency-security`, then `upgrade-packages`, `audit-allow-builds`, and `audit-ide-dependencies` | `supply-chain-harden` |
| `/devcontainer` | `devcontainer-hardened` | the dependency chain |

Workflows shipped for Grok: `.grok/workflows/dependency-harden.md`, `.grok/workflows/dependency-harden.rhai`. The copied chain names `fix-dependency-security` where the skills-repo file names `supply-chain-harden`.

Canonical files: [p10ns11y/skills](https://github.com/p10ns11y/skills) on `master`.
