# si

**SI** is the system workflow that owns the write. The model may draft. It does not own the committed record, a permission, or a price.

Install this plugin. Load the spine, then **one** profile.

| Surface | Profile |
| --- | --- |
| Not chosen yet, or a machine-first rewrite | `peram_senior_mlai_engineer` |
| Data contract, lineage, replay | `peram_data_workflows` |
| SI-native app flow: intent, draft, review, commit | `peram_si_native_workflows` |
| SI service: admit, versioned route, eval, trace | `peram_si_service_harness` |
| Deterministic SaaS: invariant, idempotent write, audit | `peram_deterministic_saas` |
| Infra: one service the product needs, cost, blast radius, security that scales | `peram_infra` |
| Devex: reproduce, verify, review, ship | `peram_devex` |

The skills library keeps sibling symlinks (`../plugins/si/skills/<name>`) so a local checkout resolves one body. GitHub does not serve those symlinks. intelli-route loads these paths from this repo.

## Install

```bash
grok plugin install ./si --trust
# slash: /si
```

## Tests

```bash
./si/test/test-thin.sh
```
