# Map schema

```text
G            : checkable arrival
x            : named facts (no PII dumps)
stages[]     : id, what (public-safe label), how, when_a, when_m, when_b, deadline?, owner,
               class ∈ {Do, Risk, Wait, Park, Done}, depends_on[],
               contact? { url, email, followup_stage, followup_when, last_touch }
               // email stays in ~/.grok/mission-maps/ only — never UI/Mission.md
critical     : ids on the longest expected chain (Done contribute te=0)
next_do      : first Do on remaining critical, else first Do, else empty
heading      : on-path | wait | park
cos          : 1 if next Do exists, 0 if only Park left, empty if Wait
residual     : remaining critical ids (not Done) toward G
effort_cap   : hours/week you will actually keep
signposts[]  : watch, fires_when, then ∈ {continue, switch, Ask}
```

JSON for the Rust CLI is the subset in `examples/sample-map.json` (`g`, `stages[].id/a/m/b/depends_on/class`).

```bash
mission-map-graph map.json --mermaid
mission-map-graph now.json --compare then.json --mermaid
mm-lifeos-graph   # 20:00 timer → ~/life-os/UI/Mission.md
```

PERT: \(t_e = (a + 4m + b) / 6\). Done stages are kept for topology and dropped from remaining \(T\).
