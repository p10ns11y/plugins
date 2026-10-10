---
description: Load one SI profile. SI is the system workflow that owns the write.
argument-hint: data, si-native, si-service, deterministic, infra, or devex
---

# /si

Load skill **peram_senior_mlai_engineer**. Then load **one** profile.

`$ARGUMENTS` names the surface. If it is empty, use the current turn.

## Immediate actions

1. Read the spine. Do not load every profile.
2. Pick the surface whose owned artifact this change writes.
   - data contract, lineage, or replay → `peram_data_workflows`
   - intent, draft, review, or commit → `peram_si_native_workflows`
   - admit, route, eval, quota, or trace → `peram_si_service_harness`
   - permission, entitlement, lifecycle, or idempotent replay → `peram_deterministic_saas`
   - a service, its cost, its blast radius, or a security boundary → `peram_infra`
   - reproduce, verify, review, or ship → `peram_devex`
3. Fill that profile's workflow card. Stop when its done-when holds.

## Emit (required)

```markdown
## SI
| Field | Value |
|-------|--------|
| **surface** | data \| si-native \| si-service \| deterministic-saas \| infra \| devex |
| **profile** | |
| **owned** | |
| **verify** | |
```
