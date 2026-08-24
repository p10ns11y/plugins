# Judgment math (on-kern)

Judgment-plane calculations only. No PERT, no DAG MC, no priors.

| Kernel | Job | Invoke |
|--------|-----|--------|
| **score** | Ithaca drift, empire_score, per-mistake harm | `on-kern score --cyclops 0.8 --drift 0.3` |
| **rank** | Mistakes sorted by harm to Ithaca | `on-kern rank --cyclops 0.8 --circe 0.2` |
| **waters** | Waters + Metis eligibility | `on-kern waters --calm --file-count 1 --greppable` |
| **eval** | Evaluate(δ) = (Correctness, Effectiveness, Efficiency) | `on-kern eval --correctness 0.9 --effectiveness 0.7 --efficiency 0.2` |
| **hubris** | Refuse Metis-in-calm, Act+auth-unknown | `on-kern hubris --metis 1 --metis-allowed 0` |

## Harm model

```text
harm(m) = exposure(m) × weight(m)
weights: Cyclops 0.95 · Helios 0.90 · Scylla 0.80 · Winds 0.75 · Sirens 0.70 · Prophecy 0.65 · Circe 0.55
```

`/odysseus-core` uses **at most one** mistake — highest harm only.

## Waters gate

```text
Metis_allowed = novel-pressure ∧ under-constrained ∧ high-pressure
calm ⇒ spirit = {Ithaca} only
```

## Consumes (does not compute)

| From | Use |
|------|-----|
| mission-map `∇T`, `cosθ` | wandering cost; suggest `/mission-map` |
| EVA emptiness signals (≥2) | `eva_hook=Ask` |
| control-graph phase | `cg_hook` label only |

## Tests

```bash
./test/test-on-kern.sh
```
