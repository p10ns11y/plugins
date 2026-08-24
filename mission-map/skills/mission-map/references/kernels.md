# Kernels

| Layer | Owns | Does not own |
|-------|------|----------------|
| **C11** `c/` | PERT \(t_e\), triangular MC on a simple path, \(d t_e/d m\), **hazard** \(P(\text{fire})\), **Bayesian PERT** update | Graphs, files, LLM |
| **Rust** `rust/` | DAG, topo, longest path, **DAG MC**, **HSMM regime** filter, **Risk rank**, JSON I/O | Oracle forecasts |
| **LLM** | Propose missing stage / \(a,m,b\) / signpost | Write params without HITL |

## C (`mm-kern`)

```bash
mm-kern pert <a> <m> <b>              # te, sigma
mm-kern mc <a> <m> <b> [a m b ...]    # path mean/p50/p90 (fixed chain)
mm-kern grad <a> <m> <b>              # d(te)/d(m)
mm-kern hazard <lambda> <tau> [<blast>]  # P(fire), E[delta_T]
mm-kern bayes <a> <m> <b> <t_actual>     # updated a/m/b after completion
```

## Rust (`mission-map-graph`)

```bash
mission-map-graph map.json [--mermaid] [--compare then.json] [--risk-tau 4]
```

Extra output lines:

| Field | Meaning |
|-------|---------|
| `dag_mc_p50`, `dag_mc_p90` | Project remaining time under DAG MC (critical path may switch) |
| `critical_prob <id>=` | P(stage on critical path) when ≥ 0.25 |
| `regime_on_track`, `regime_slow`, … | HSMM belief after `--compare` |
| `risk id= p_fire= e_delta_te=` | Ranked Risk stages: \(\lambda\), blast, horizon \(\tau\) |

## Math (not destiny dates)

- **DAG MC:** sample triangular durations per stage → longest path each draw → p50/p90 + critical-path frequencies.
- **Bayesian PERT:** pull \(m\) toward observed \(t_{\text{actual}}\); shrink \([a,b]\).
- **Hazard:** \(P(\text{fire by }\tau) = 1 - e^{-\lambda\tau}\); \(E[\Delta T] = \text{blast} \cdot P\).
- **HSMM regime:** forward filter on `delta_te`, `completed`, `heading` — on_track / slow / blocked / distracted.

```bash
make -C c test
cd rust && cargo test
```
