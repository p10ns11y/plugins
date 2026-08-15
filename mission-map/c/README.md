# mm-kern (C)

Leaf math for mission-map. No graphs, no files, no LLM.

## Build

```bash
make                 # → ../bin/mm-kern
# flags: -std=c11 -Wall -Wextra -Werror -Wconversion -Wshadow -O2
```

## CLI

```bash
mm-kern pert <a> <m> <b>           # te and sigma
mm-kern mc   <a> <m> <b> [...]     # path mean / p50 / p90
mm-kern grad <a> <m> <b>           # d(te)/d(m) = 4/6
```

Times are in the same unit you pass (usually weeks). `a<=m<=b`, `a>=0`.

## Files

| File | Owns |
|------|------|
| `mm_pert.c` | PERT expected and sigma |
| `mm_mc.c` | Triangular samples on a simple path |
| `mm_grad.c` | Sensitivity of te to mode |
| `main.c` | CLI |

Graph / critical path lives in `../rust`.
