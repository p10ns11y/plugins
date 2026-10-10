---
name: peram_data_workflows
description: >
  Workflow for data that outlives the model: name the record, write the
  contract, gate quality, serve only checked data, and version readers.
  Use for /peram_data_workflows, data contracts, lineage, schema changes,
  pipelines, replay, or any feature whose owned artifact is a dataset.
version: 1.0.0
author: p10ns11y
tags: [data, contract, lineage, quality-gate, workflow]
category: software-development
---

# peram_data_workflows

> **Load rule:** Data surface only. Spine: [peram_senior_mlai_engineer](../peram_senior_mlai_engineer/SKILL.md). Card: [workflow-card.md](../peram_senior_mlai_engineer/references/workflow-card.md).

The dataset, the contract, and the lineage stay. A model is a reader. Swap the reader without rewriting the store.

## When

- A pipeline, table, feature store, export, or training set is the thing being changed
- A schema, unit, identity, or null rule is unclear
- A consumer (API, screen, model) is about to read data that has no gate

## Skip

- Copy or layout with no data contract
- The write is a business transition (permission, billing, record lifecycle) — use [peram_deterministic_saas](../peram_deterministic_saas/SKILL.md)
- The write is a model draft a person has not accepted — use [peram_si_native_workflows](../peram_si_native_workflows/SKILL.md)

## Workflow

```text
named → contracted → gated → served → revised → retired
                         ↘ rejected (not served)
```

| State | Owned artifact | Exit |
| --- | --- | --- |
| named | Record: identity, owner, time basis, unit | A stranger can point at one row |
| contracted | Schema, nulls, units, allowed values | A bad row fails the contract |
| gated | Quality result for this batch | Fail closed, or an explicit waiver with a name |
| served | A reader bound to a contract version | Reader sees only gated data |
| revised | Next contract version plus a migration note | Old readers still name their version |
| retired | Successor pointer or a tombstone | No silent reader remains |

## Objects

| Object | Job |
| --- | --- |
| Record | The fact that is stored |
| Contract | What a valid record is, at a version |
| Batch | One ingest or backfill, idempotent |
| Gate | Pass, fail, or named waiver before serve |
| Reader | API, screen, or model pinned to a contract version |
| Lineage edge | Source → transform → reader |

## Steps

1. Fill the workflow card. `owned` is the record or the contract, not the model output.
2. Name identity, owner, time basis, and unit in one place. Do this before a notebook explores the file.
3. Write the contract: fields, types, nulls, units, and what "missing" means.
4. Make ingest replayable. The same batch applied twice does not duplicate rows or move a metric.
5. Run the gate. A contract break does not reach serve.
6. Bind each reader to a contract version. A model prompt is not a schema.
7. To change the contract: add a version, migrate or dual-read, then move readers. Retire the old version with a pointer.

## Done when

- The card's verify line is a replay or a contract test, and it passed
- A new reader can be pointed at a contract version without a new store
- A bad batch is rejected and the previous served version is unchanged
- Lineage names source, transform, and reader for the batch you touched

## Do not

- Train, embed, or prompt against uncontracted files
- Let the model invent fields the store does not own
- Hide the schema inside a notebook or a prompt
- Backfill without an idempotency key and a contract version
- Treat a dashboard label as the unit of the measure
