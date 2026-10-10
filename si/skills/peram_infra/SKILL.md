---
name: peram_infra
description: >
  Workflow for services: add one only when the product needs it, keep the
  blast radius small, name the cost before it scales, and let security grow
  with scale. Complexity stays inside the product's nature. Use for /peram_infra,
  service boundaries, cost, rollback, least privilege, or infra that must scale.
version: 1.0.0
author: p10ns11y
tags: [infra, services, cost, security, blast-radius, workflow]
category: software-development
---

# peram_infra

> **Load rule:** Services only. Spine: [peram_senior_mlai_engineer](../peram_senior_mlai_engineer/SKILL.md). Card: [workflow-card.md](../peram_senior_mlai_engineer/references/workflow-card.md).

A service exists because the product needs it. Complexity stops at that need. Cost is named before the service grows. Security is what scales.

## When

- Adding, splitting, or retiring a service, queue, store, or network boundary
- A change widens privilege, spend, or blast radius
- Scale is the reason for a new moving part

## Skip

- The owned write is a data contract — use [peram_data_workflows](../peram_data_workflows/SKILL.md)
- The owned write is a model route or eval — use [peram_si_service_harness](../peram_si_service_harness/SKILL.md)
- The owned write is a business transition — use [peram_deterministic_saas](../peram_deterministic_saas/SKILL.md)
- The owned change is the builder's path — use [peram_devex](../peram_devex/SKILL.md)

## Workflow

```text
needed → bounded → secured → costed → shipped → retired
       ↘ refused (the product does not need this service)
```

| State | What is true |
| --- | --- |
| needed | One product behavior names this service. No behavior, no service |
| bounded | One duty. Rollback restores the previous good state. Blast radius is one service |
| secured | Identity, least privilege, secret handling, network boundary, and audit exist before traffic grows |
| costed | Unit and budget are written (request, byte, seat, or hour). A cheaper path that meets the product wins |
| shipped | The service is reachable only inside its boundary. Rollback has been run or scripted |
| retired | Nothing calls it. The privilege and the spend are gone |

## Steps

1. Fill the card. `owned` is the service boundary, not a diagram.
2. Write the product behavior in one sentence. If the sentence is "platform" or "later", refuse the service.
3. Give it one duty and a rollback. A change that cannot roll back does not ship.
4. Put security on the path before scale: who may call it, which secret it may read, which network it may join, what audit row it writes. Widen these only when the product's scale requires it.
5. Name the cost unit and the budget. Check them again before any scale step. Do not add a cluster, mesh, or extra region the product is not using.
6. List every new moving part. Each one maps to users, data, failure, or a real constraint. A part that maps only to fashion is deleted.
7. Ship. When scale changes, revisit privilege and cost. Do not revisit by adding a service.

## Done when

- The card names the product behavior, the cost unit, the security boundary, and the rollback
- A service with no product behavior was refused, or this one has that sentence
- Privilege is no wider than the product requires, and the verify line is a privilege check or a rollback drill
- Spend without a budget cannot ship

## Do not

- Add a service for later
- Scale by copying a platform diagram
- Put secrets in images, logs, prompts, or the repo
- Let a model choose identity, network policy, or spend
- Make a security control optional once traffic grows
- Take on complexity the product's nature does not force
