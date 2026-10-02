---
name: split-machine
version: 0.2.0
description: >
  Place one job on the machine that can do it. Earth keeps the QPU and the
  GPUs. Orbit keeps three different jobs apart: an entanglement link, a
  classical LEO radio handover, and a conjunction screen. A closed decision
  software will branch on is System One and carries a confidence. Prose is
  System Two. Use for /split-machine, quantum vs GPU, Hamiltonian wording,
  NISQ scope, beam switching, Stargaze, or "which machine".
---

# split-machine

> **Load rule:** This file owns the placement. Tables live in [references/placement.md](references/placement.md). Open that file only to pick the row. Do not paste the posts or the System One writeup into the turn.

```text
// Signature
SM   : split-machine (this skill)
QPU  : earth processor — state evolved under Ĥ, then a measurement
ORB  : orbit link — entanglement between ground stations
RF   : beam-switch — one serving classical radio path, many LEO satellites in view
SSA  : orbit-screen — trajectory estimate and conjunction screen
GPU  : classical factory — dense linear algebra and token serving
BQP  : one slice whose structure is quantum simulation, factoring-class, or an Ising inner loop
S1   : typed decision + confidence, consumer is code
S2   : string a person will read

// Axioms
A1  One substrate. A second machine is a neighbor, not a second answer.
A2  Name the act. Do not say the computer computed it.
A3  The state evolves under Ĥ. Ĥ may be a schedule Ĥ(t). You do not evolve the Hamiltonian.
A4  A dilution refrigerator, an ion or atom QPU, and a millisecond loop with the cluster stay on Earth.
A5  Entanglement distribution is orbit-link. Classical line-of-sight radio is beam-switch. Free-fall can be a clock or an interferometer; that instrument is not a communication link.
A6  A branch in code is a closed value plus a confidence. Low confidence does not branch.
A7  NISQ is not production inference. A QPU is not a faster matmul.
A8  One radio path is serving. Candidates in view are not a second session. Switch on the obstruction map. A stale clear path is not the current path.
A9  An optical track becomes a trajectory, then a screen. A thrusting owner's ephemeris outranks a track from before the burn. Star trackers are not a deep-space telescope.
```

**Mission:** One substrate, one act, one confidence, one next step — or a refusal.

---

## Activate / Skip

| Signal | Action |
|--------|--------|
| Quantum, QPU, NISQ, BQP, Hamiltonian, entanglement, fridge | Activate |
| LEO handover, obstruction, beam switching, conjunction, Stargaze, space situational awareness | Activate |
| "Which machine", GPU vs QPU, train-on-quantum | Activate |
| A program must branch on a classification, score, or route | Activate as `system-one` |
| The deliverable is only prose or code, no machine choice | `system-two`, or skip if placement is already fixed |
| One-file edit with a known test and no hardware claim | Skip |

Slash: `/split-machine`.

---

## Instructions

1. Name the job in one sentence. If two jobs are glued together, split them and place each.
2. Pick one substrate from [references/placement.md](references/placement.md).
3. Write the act in that row's verbs. For `earth-qpu` and `bqp-slice`, the act is an evolution and a measurement, not "computed". For `beam-switch` and `orbit-screen`, the act is classical. Do not write a Hamiltonian for it.
4. Set confidence `high`, `med`, or `low`. `low` stops the automation. The next step is the question a person must answer.
5. Name what you refused, in one line.
6. Hand the card to intelli-route when this skill was loaded as a signal. It does not replace the route. It constrains the next step.

### Neighbors

| Substrate | Often beside it |
|-----------|-----------------|
| `bqp-slice` | `gpu-factory` compiles, calibrates, and decodes. AI sits in that loop. |
| `orbit-link` | `earth-qpu` owns the circuit. Classical control traffic stays on the ground. |
| `beam-switch` | `orbit-screen` may watch the vehicles. A conjunction message does not steer the user beam. |
| `orbit-screen` | `beam-switch` keeps the radio path. The screen does not serve tokens. |
| `system-two` | `system-one` may score the string. The string is not the branch. |
| `gpu-factory` | `uncertainty-laws` if the choice is a bet. `mission-map` if the choice is a path. `trust-stack` if the question is whether the agent may ship. |

---

## Emit (required)

```markdown
## Split
| Field | Value |
|-------|--------|
| **job** | |
| **substrate** | earth-qpu · orbit-link · beam-switch · orbit-screen · gpu-factory · bqp-slice · system-one · system-two |
| **act** | |
| **confidence** | high · med · low |
| **refused** | |
| **wording** | one sentence in the legal voice |
| **next** | one step, or the question if confidence is low |
```

---

## Examples

User: keep one user session up while LEO satellites hand the radio path over.
Agent: substrate `beam-switch`. Act: switch the beam. Refused: calling the handover `orbit-link`.

User: two LEO objects may pass too close.
Agent: substrate `orbit-screen`. Act: screen the conjunction. Refused: a miss-distance from before a burn.

User: hand an entangled pair to two ground stations.
Agent: substrate `orbit-link`. Act: distribute entanglement. Refused: a radio handover or a free-fall clock.

## Done when

- One substrate from the closed set
- The act matches that row
- Confidence is set, and `low` did not take a branch
- No claim that a quantum device ran dense training or live token serving
- No claim that a radio handover or a conjunction screen is an entangled pair
- No claim that this plugin called a System One vendor or a Starlink API

## Limitations

- Not a device driver, a compiler, a cloud QPU client, or a conjunction-screening client.
- Does not estimate shot counts, fidelities, miss distances, or pass schedules.
- Vendor dates for fault tolerance stay directional. Do not treat them as a plan.
