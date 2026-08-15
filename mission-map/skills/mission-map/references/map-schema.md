# Map schema

```text
G            : checkable arrival
x            : named facts (no PII dumps)
stages[]     : id, what, how, when_a, when_m, when_b, deadline?, owner,
               class ∈ {Do, Risk, Wait, Park}, depends_on[]
critical     : ids on the longest expected chain
next_do      : exactly one stage id
effort_cap   : hours/week you will actually keep
signposts[]  : watch, fires_when, then ∈ {continue, switch, Ask}
```

JSON for the Rust CLI is the subset in `examples/sample-map.json` (`g`, `stages[].id/a/m/b/depends_on/class`).

PERT: \(t_e = (a + 4m + b) / 6\).
