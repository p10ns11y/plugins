# context-ignite

Installable fission then fusion. This plugin keeps three things.

1. **Spec.** `/context-ignite` loads `ai-optimization`, then `architecture-synthesis`. Those skill files are the procedure.
2. **Policy.** Canonical files stay in [p10ns11y/skills](https://github.com/p10ns11y/skills) on `master`. `intelli-route` paths stay unchanged. `fusion-sage` is not copied.
3. **Before/after.** The pull request records files changed, `bash test/test-thin.sh`, and `python3 scripts/gen-catalogs.py --check`.

The skills repo remains the canonical URL until a later issue switches `intelli-route`.

| Slash | Loads |
| --- | --- |
| `/context-ignite` | `ai-optimization`, then `architecture-synthesis` |

Workflows: `.grok/workflows/context-ignite.rhai` and `.grok/workflows/context-ignite.md`. Copy them into a discovery root. Plugins do not auto-register Rhai.

If a host compaction pass beats context-sage.py on a real repo, delete the prune half and keep architecture-synthesis.

Canonical files: [p10ns11y/skills](https://github.com/p10ns11y/skills) on `master`.
