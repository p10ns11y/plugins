# SkillEvaluator pass — mission-map — 2026-09-08

Companion to `p10ns11y/skills` `docs/eval/2026-09-08/`. Same wave evaluated plugin skill [`mission-map`](../../mission-map/skills/mission-map/).

## Results (after SKILL.md Tier1 fixes)

| Target | Grade | Score /100 | Notes |
|--------|-------|------------|-------|
| mission-map (plugin skill) | **A** | **100.0** | `quality-check` PASS. Schema 11/11 PASS. Gitleaks PASS. PII PASS. |

Full `validate --tiers 1` is still **INCOMPLETE**: SkillSpector JSON (`risk_assessment.recommendation` vs severity) does not match what SkillEvaluator 0.2.1 expects. Direct `skillspector scan` ran; LLM analyzers failed (model not found). That is a tool-contract gap, not a missing SKILL.md field.

Artifacts: [artifacts/](artifacts/).

## How (tools → tasks)

Same eval-host stack as skills repo:

```text
Orca orchestration Run + Grok/cursor workers
  → NVIDIA SkillEvaluator 0.2.1 quality-check / validate
  → this doc + improvement list
```

See skills write-up for the full tools→tasks table and Orca Run id.

## Tier1 SKILL.md fixes landed

1. Frontmatter: `version: 0.1.0`, `metadata.author` as `Name <email@host>` (GitHub noreply), `metadata.tags`.
2. Description shortened to 122 characters.
3. Body sections: Purpose, Prerequisites, Instructions, Examples, Limitations, Troubleshooting.
4. Validation: empty \(G\) or empty DAG stops and Asks. Troubleshooting table for `mm-kern`, JSON, overwrite.
5. Gitleaks on PATH: secrets scan PASS.

Still open: SkillSpector vs SkillEvaluator JSON contract; Tier2/Tier3 live eval.

## Owner

Steward · eval-host · paired with skills eval 2026-09-08.
