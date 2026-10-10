---
name: peram_deterministic_saas
description: >
  Workflow for classical deterministic SaaS: one invariant, an explicit state
  machine, server-side authorization, idempotent writes, and an audit row.
  Use for /peram_deterministic_saas, permissions, billing state, record
  lifecycle, imports, or any write that must replay to the same result.
version: 1.0.0
author: p10ns11y
tags: [saas, state-machine, idempotency, authorization, workflow]
category: software-development
---

# peram_deterministic_saas

> **Load rule:** Deterministic business writes only. Spine: [peram_senior_mlai_engineer](../peram_senior_mlai_engineer/SKILL.md). Card: [workflow-card.md](../peram_senior_mlai_engineer/references/workflow-card.md).

The same command on the same state returns the same result. A model may draft text around the workflow. It does not take the transition.

## When

- Create, update, archive, invite, approve, entitlement, or import
- A double submit must not double-charge, double-create, or double-send
- The screen is showing buttons that are really states

## Skip

- The owned write is a dataset contract — use [peram_data_workflows](../peram_data_workflows/SKILL.md)
- The owned write is a reviewed model draft — use [peram_si_native_workflows](../peram_si_native_workflows/SKILL.md)
- You are versioning a model route or eval — use [peram_si_service_harness](../peram_si_service_harness/SKILL.md)

## Pick one workflow

One card, one invariant.

| Workflow | Invariant shape |
| --- | --- |
| Record lifecycle | A record is in one state; only listed transitions apply |
| Permission | A grant or revoke matches a role the actor holds |
| Entitlement | An entitlement changes only from its current state, once per idempotency key |
| Import | A file applies fully or not at all, and a second apply is a no-op |
| Operator action | A privileged transition has an actor, a reason, and an audit row |

## Workflow

```text
proposed → authorized → applied → recorded
         ↘ rejected (state unchanged)
```

| State | Who writes | Notes |
| --- | --- | --- |
| proposed | Client | Intent plus idempotency key plus expected current state |
| authorized | Server | Actor may take this transition from this state |
| applied | Server | Store matches the new state. Replay does not apply twice |
| recorded | Server | Audit row for transitions that matter |
| rejected | Server | Current state is unchanged and is returned |

The UI renders allowed transitions. It does not decide them.

## Steps

1. Write the invariant as one sentence on the card.
2. List states and legal transitions. Name who may take each one.
3. Authorize on the server from actor, current state, and transition. A hidden button is not authorization.
4. Require an idempotency key and the expected current state. Mismatch rejects.
5. Apply once. A replay with the same key returns the original result and does not repeat side effects.
6. Append an audit row: actor, transition, from-state, to-state, time. Skip this only when the transition cannot matter later, and say why on the card.
7. Test one legal transition, one illegal transition, and one replay.

## Done when

- Replay of the same command does not double-apply
- An illegal transition is rejected and the stored state is unchanged
- A test name contains the invariant
- The client cannot reach `applied` except through the server transition

## Do not

- Encode the workflow only in the frontend
- Scatter conditions that are unnamed states
- Let a model choose permission, price, or entitlement
- Send email, charge, or publish as a side effect that replay can repeat
- Migrate data with a script that is not idempotent and not tied to a contract version — that part is [peram_data_workflows](../peram_data_workflows/SKILL.md)
