# Kernels

| Layer | Owns | Does not own |
|-------|------|----------------|
| **C11** `c/` | PERT \(t_e\), triangular MC on a simple path, \(d t_e/d m\) | Graphs, files, LLM |
| **Rust** `rust/` | DAG, topo, longest path, JSON I/O, calls C for numbers | Oracle forecasts |
| **LLM** | Propose missing stage / \(a,m,b\) / signpost | Write params without HITL |

```bash
make -C c test
cd rust && cargo test
```
