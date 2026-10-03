---
description: Run the clean-code agent chain with CRAP and mutation score checks on touched functions. Work in progress per Robert C. Martin.
argument-hint: spec path or story name
---

# /craft

Load skill **craft**. Open `references/chain.md` only to pick the step. Open `references/thresholds.md` for numbers.

`$ARGUMENTS` is the spec or story. If empty, use the current turn.

## Immediate actions

1. Acceptance tests come from the spec before any implementation agent runs. Write Gherkin and a QA procedure first. If not, write them from the spec and stop.
2. Run coder, then cleaner with `craft/bin/crap-score.py --max 6` on touched functions.
3. Run hardener with `craft/bin/mutation-score.py --min 0.95` on the same functions.
4. Boy-scout only inside files the change already touches.
5. Emit the Craft card. Do not merge.

## Emit (required)

```markdown
## Craft
| Field | Value |
|-------|--------|
| **spec** | |
| **acceptance** | written before coder: yes \| no |
| **step** | acceptance · coder · cleaner · hardener · qa · done |
| **touched** | |
| **crap_max** | |
| **mutation** | |
| **scout** | touched files only \| violated |
| **next** | |
```

Credit Robert C. Martin's chain as work in progress. See `NOTICE.md`.
