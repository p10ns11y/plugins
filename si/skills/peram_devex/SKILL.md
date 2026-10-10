---
name: peram_devex
description: >
  Workflow for the builder path: reproduce, change, verify, review, ship.
  The path is only as long as the product requires, and the fast path is the
  secure one. Use for /peram_devex, local setup, verify commands, review,
  or the documented way a change ships.
version: 1.0.0
author: p10ns11y
tags: [devex, verify, reproduce, review, workflow]
category: software-development
---

# peram_devex

> **Load rule:** The builder path only. Spine: [peram_senior_mlai_engineer](../peram_senior_mlai_engineer/SKILL.md). Card: [workflow-card.md](../peram_senior_mlai_engineer/references/workflow-card.md).

The path a person takes to change the product. It is only as complex as that product. The fast path does not turn security off.

## When

- Setup, the verify command, review, or the ship path is the thing being changed
- A new checkout cannot reach a passing check from the documented command
- Local and CI disagree

## Skip

- The owned write is a service boundary, privilege, or spend — use [peram_infra](../peram_infra/SKILL.md)
- The owned write is product data, a review flow, a model route, or a business transition — use that profile
- A one-line fix whose verify command already exists and passes

## Workflow

```text
reproduced → changed → verified → reviewed → shipped
                                 ↘ blocked (verify failed; the shipped tree stays)
```

| State | What is true |
| --- | --- |
| reproduced | The documented command reaches a working tree. The doc and the command match |
| changed | The edit stays on one product surface |
| verified | The local check is the CI check. It failed closed or it passed |
| reviewed | The diff, the verify result, and the rollback are what review sees |
| shipped | A new person can run the same path from the doc |
| blocked | Verify failed. Nothing shipped |

## Steps

1. Fill the card. `owned` is the documented command and the check it runs.
2. Make one command reproduce the environment. If the doc and the command disagree, fix that before the feature.
3. Keep the change inside one product profile. Devex does not invent a second way to write data, permissions, or services.
4. Point local verify and CI at the same command. Name it on the card.
5. Keep secrets and production credentials off this path. Use a fixture.
6. Review is the diff, the verify result, and how to roll back. Cut any extra ceremony that does not protect the product or the builder.
7. Ship only from the documented path.

## Done when

- A clean checkout reaches verify with the command in the doc
- That command is the one CI runs
- The fast path does not ask for a secret
- Steps that do not protect the product or the builder are gone

## Do not

- Leave the real steps in a private note
- Make the dev path more complex than the product
- Turn security off so local is "easier"
- Document a command that is not the one CI runs
- Widen production privilege from a dev convenience
