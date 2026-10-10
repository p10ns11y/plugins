---
name: peram_si_service_harness
description: >
  Product engineering for SI as a service: admit the request, assemble
  context under a budget, call a versioned route, check the output, then
  serve, fall back, or refuse — with a trace. Use for /peram_si_service_harness,
  evals, prompt versions, model routing, quotas, fallbacks, or the harness
  around a model API.
version: 1.0.0
author: p10ns11y
tags: [si-service, harness, eval, routing, trace, product]
category: software-development
---

# peram_si_service_harness

> **Load rule:** The service around the model, not the screen. Spine: [peram_senior_mlai_engineer](../peram_senior_mlai_engineer/SKILL.md). Card: [workflow-card.md](../peram_senior_mlai_engineer/references/workflow-card.md). Person-facing states: [peram_si_native_workflows](../peram_si_native_workflows/SKILL.md).

The harness is the product. The model is a dependency behind a versioned route.

## When

- A feature calls a model as a service (yours or a provider)
- You are changing a prompt, route, budget, fallback, or eval
- You cannot say which version produced a given response

## Skip

- The task is only how the draft appears and how a person accepts it — use [peram_si_native_workflows](../peram_si_native_workflows/SKILL.md)
- The task is the stored dataset — use [peram_data_workflows](../peram_data_workflows/SKILL.md)
- The outcome must be the same with no model (permission, price, ledger) — use [peram_deterministic_saas](../peram_deterministic_saas/SKILL.md)

## Workflow

```text
admit → assemble → route → check → serve
                              ↘ fallback → check → serve | refuse
                              ↘ refuse
        trace is written on every exit, including refuse
```

| State | What is true |
| --- | --- |
| admit | Caller is allowed, quota remains, input matches the contract. Otherwise refuse before any model call |
| assemble | Context pack is inside a token and time budget. Inclusions are listed |
| route | Model and prompt are a named version, not an inline string in the UI |
| check | Output matches the output contract and the policy. An eval slice covers this change |
| serve | Caller receives output plus the version id |
| fallback | A narrower route or a deterministic reply, then check again |
| refuse | No fabricated success. Reason is safe to show |

## Steps

1. Fill the card. `owned` is the route version or the eval slice, plus the trace for this request.
2. Write the input contract and the output contract. Refuse on mismatch.
3. Check authorization and quota in admit. Do not spend a model call to discover a denial.
4. Assemble context under an explicit budget. Record what was included and what was cut.
5. Call the versioned route through an adapter. The provider SDK is replaceable.
6. Check the output. Ship a prompt or route change only when its eval slice passes.
7. On failure: fallback if a narrower path exists, otherwise refuse. Write the trace either way: version, latency, token use, decision, contract ids.

Human review, when the product needs it, is a state the API returns (draft, needs review). It is not a side channel.

Cost and latency belong on the request contract. They are product limits.

## Done when

- One real or fixture response names its route version, its decision (serve, fallback, refuse), and its cost or token use
- A prompt or route edit in this change is tied to an eval slice that passed, or the change is a refusal-path only and a test shows the refusal
- A contract-breaking input never reaches the model
- The provider client can be swapped without changing admit, check, or trace

## Do not

- Call the model from a click handler with an unversioned prompt
- Treat a green provider status page as an eval
- Log secrets, raw credentials, or private payloads into the trace
- Return a guessed answer when check fails
- Let the model set its own quota, price, or permission
