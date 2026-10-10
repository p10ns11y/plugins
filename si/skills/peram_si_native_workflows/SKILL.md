---
name: peram_si_native_workflows
description: >
  Workflow for SI-native app elements and UI: intent, context pack, draft,
  diff, review, and commit. The screen is a state machine. Use for
  /peram_si_native_workflows, SI-native UX, draft versus commit, streaming
  states, review flows, or presentation of model output.
version: 1.0.0
author: p10ns11y
tags: [si-native, workflow, ui, ux, presentation-layer, review]
category: software-development
---

# peram_si_native_workflows

> **Load rule:** App workflow and presentation only. Spine: [peram_senior_mlai_engineer](../peram_senior_mlai_engineer/SKILL.md). Card: [workflow-card.md](../peram_senior_mlai_engineer/references/workflow-card.md). The service path around the model is [peram_si_service_harness](../peram_si_service_harness/SKILL.md).

The person moves through named states. The model is allowed on **drafting** only. Commit is a separate write.

## When

- A screen or API lets a person ask, receive a draft, and accept a change
- Streaming, empty, slow, failed, or refused states are part of the task
- Model output is about to look like a finished record

## Skip

- No person reviews the result and the output must be deterministic — use [peram_deterministic_saas](../peram_deterministic_saas/SKILL.md)
- You are changing the dataset contract, not the flow — use [peram_data_workflows](../peram_data_workflows/SKILL.md)
- You are changing route, eval, quota, or trace — use [peram_si_service_harness](../peram_si_service_harness/SKILL.md)

## Workflow

```text
idle → gathering → drafting → reviewing → committed
                 ↘ failed      (last commit kept)
                 ↘ refused
                 ↘ abandoned
```

Walk this with a fixture and no live model before you attach one.

## Elements

Each element is a workflow object. It is not a visual kit.

| Element | Job | The person must be able to tell |
| --- | --- | --- |
| Intent | What was asked | The person's words, not a hidden rewrite |
| Context pack | What the system was allowed to read | Sources, and what was left out |
| Draft | Model output | That it is a draft; streaming is not "done" |
| Diff | What commit would change | Before and after on the owned record |
| Review | Accept, edit, reject, regenerate | One primary action; reject keeps the last commit |
| Commit | The write that sticks | Who committed, and which draft |
| Trace | Why this draft | Route and version, on demand — not a wall of logs |

Empty, slow, failed, and refused are designed before the happy path. Partial text stays marked partial until review.

## Presentation

- The machine core keeps terse ids, scores, and structures.
- The screen uses the person's words and the domain's words.
- The safe action is the default. Commit is never the default while the draft is still streaming.
- Undo returns to the last commit.
- A confidence number does not skip review.

## Steps

1. Fill the card. `owned` is the committed artifact (document, record, message), not the draft.
2. List legal transitions, including failed, refused, and abandoned.
3. Place the model only on the drafting edge.
4. Make review the only path to commit. Edit-then-commit is still a review.
5. Specify empty, slow, failed, and refused copy and what remains on screen.
6. Walk every transition with fixtures. No network model.
7. Attach the model. Streaming updates the draft element only.

## Done when

- A person can distinguish draft from committed without reading source
- A failed or refused generation leaves the last commit intact
- The fixture walk covers happy, empty, failed, and reject
- Machine ids are not the labels on the screen

## Do not

- Render a stream as a finished answer
- Write the committed store from the model callback
- Use the model to decide whether the person is allowed to commit
- Invent a second visual system when the product already has one — map these elements onto it
- Hide the context pack when the draft depends on private or retrieved text
