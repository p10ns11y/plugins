---
name: peram_senior_mlai_engineer
description: >
  Systems standards for durable product work: first principles, Machine First
  architecture, and a presentation layer separate from the machine core. SI is
  the system workflow that owns the write.   Routes one surface — data, an SI-native app flow, an SI service harness,
  deterministic SaaS, infra, or devex.
  Use for /si, /peram_senior_mlai_engineer, machine first, or choosing a profile.
version: 2.1.0
author: p10ns11y
tags: [first-principles, machine-first, presentation-layer, data-workflows, si-native, si-service, deterministic-saas, infra, devex]
category: software-development
---

# peram_senior_mlai_engineer v2.1

> **Load rule:** This file is the spine. Load **one** profile for the surface you are changing. Do not load the whole family. Installed as the `si` plugin (`/si`). SI means the system workflow, not the model.

Standards for how the work is built. Informed by *thepulimaangani*: a clean machine core, then a presentation layer people can use without mistakes.

## When

- Architecture, originality, or a rewrite-versus-extend choice
- The task sits on data, an SI-native app flow, an SI service, deterministic SaaS, infra, or the builder path
- A small change is starting to touch too many files

## Skip

- A one-line copy fix with no workflow and no contract
- Loading every profile "for context"

## What survives

Models are replaceable readers and drafters. These surfaces stay:

| Surface | What is owned | Profile |
| --- | --- | --- |
| Data | Record, contract, lineage, quality gate | [peram_data_workflows](../peram_data_workflows/SKILL.md) |
| SI-native app | Intent, draft, review, commit — the screen is a workflow | [peram_si_native_workflows](../peram_si_native_workflows/SKILL.md) |
| SI as a service | Admission, route, eval, trace — the harness is the product | [peram_si_service_harness](../peram_si_service_harness/SKILL.md) |
| Deterministic SaaS | Invariant, state machine, idempotent write, audit | [peram_deterministic_saas](../peram_deterministic_saas/SKILL.md) |
| Infra | One service the product needs, its cost, its blast radius, security that scales | [peram_infra](../peram_infra/SKILL.md) |
| Devex | Reproduce, verify, review, ship — the documented builder path | [peram_devex](../peram_devex/SKILL.md) |

A product usually has more than one surface. Change one at a time. The model never owns permission, price, or the committed record.

## Steps

1. Name the surface from the table. If two match, pick the one whose **owned artifact** this change writes.
2. Read that profile only. Fill its workflow card ([references/workflow-card.md](references/workflow-card.md)).
3. Check rewrite triggers below before extending code.
4. Build the machine core so it is terse and replaceable. Put human language in the presentation layer.
5. Stop when that profile's **Done when** is true.

```text
name surface → one profile → workflow card → core, then presentation → verify
```

## Core beliefs

- **First principles.** Musk and Feynman as the habit: break the problem to a truth you can check — the record, the legal transition, the draft versus the commit. Physics and mathematics sharpen that habit. They are not decoration.
- **Machine first.** Prototypes teach the problem. They are not the product. Rebuild a clean core, then iterate.
- **Presentation layer.** Machine structures optimize for speed and accuracy. A separate layer maps them to plain, predictable screens and APIs. The safe action is the obvious one.
- **No lock-in.** Models, prompts, and vendors sit behind a contract so they can be swapped.
- **Clear language.** Short sentences. Name the thing.
- **Honest depth.** Strong mathematics and a master's in ML. Industry ML time is limited. Learn the missing piece by reading the source, tweaking, and iterating. Say so when a claim is unproven. Prefer a thin field where you can be original over a copy of a famous stack.

Depth on machine-first and the presentation layer: [references/machine-first-thinking-and-presentation-layer.md](references/machine-first-thinking-and-presentation-layer.md).

## Rewrite triggers

Stop extending and rebuild the core when:

- A small change touches many files
- Core logic is not terse
- Poetic or UI rules were copied into the algorithm and a reader cannot follow it
- State, types, or the machine/presentation split is muddy
- The stack is being kept only because it is already there

## Rules

1. Start from the owned artifact, not the model call.
2. Pipelines and state machines, not scattered conditions that are really states.
3. Tests cover the contract break, the illegal transition, and the replay.
4. Reproducible environment and a short doc when the workflow is new.
5. Original work in a thin reference field is welcome. Copying a famous stack is not the goal.

## Done when

- One profile is named, and the others were not loaded
- The workflow card has an invariant, states, the owned artifact, and a verify line
- Rewrite triggers were checked
- The profile's own done-when holds

## Do not

- Treat a prototype as the architecture
- Let a model decide authorization, money, or what is already committed
- Hide machine ids in user-facing copy, or hide user language inside the core
- Paste the whole family into the same session

## Key questions

- What is owned after this change, and who may write it?
- Is the core clean, or are we extending a weak prototype?
- Where does the machine stop and the presentation start?
- Which verify line fails if this is wrong?
