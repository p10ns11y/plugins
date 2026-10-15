# tstack

pstack paces the code. tstack paces the person: one 🍅 block at a time.

```mermaid
flowchart LR
  C[capture-sweep] --> M[mission-map]
  M --> R{intelli-route}
  R -->|repo work| P[pstack-map]
  R -->|closed decision| K[concordance]
  R -->|life or mission| T[tomato-loop]
  K -->|hold| H[[HITL card]]
  K -->|proceed| T
  T -->|send, pay, sign| H
  T --> V[harvest]
  P --> V
  V --> PM[(pulse-memory)]
  PM --> M
```

Commands: `/tomato`, `/harvest`, `/replan`. Route table: [references/map.md](references/map.md).
Needs `premflow` on PATH for timed blocks. Loads mission-map, intelli-route, control-plane, pulse-memory, steer-log, steer-accel, concordance, trust-stack, si, michelin-kitchen and pstack-map; copies none. Credits: [NOTICE.md](NOTICE.md).
