---
description: Corroborate one closed decision. Proceed only when the two labels match and p_dm >= tau. Hold returns to the router.
argument-hint: label_dm, label_llm, p_dm, and tau
---

# /concordance

Load skill **concordance**. Open `references/card.md` only to append one log line.

`$ARGUMENTS` is the case. If it is empty, use the current turn.

## Immediate actions

1. Read the two labels, `p_dm`, and `tau`. Leave a missing input empty.
2. `agree` is `yes` only when both labels are the same token.
3. proceed only when agree is yes and p_dm >= tau. Every other case is `hold`.
4. Leave `kappa_window` empty when the caller supplied no window.
5. On `hold`, stop. intelli-route routes the hold. Do not pick a load.

## Emit (required)

```markdown
## Concordance
| Field | Value |
|-------|--------|
| **label_dm** | |
| **label_llm** | |
| **agree** | yes \| no |
| **p_dm** | |
| **kappa_window** | optional, over recent cases |
| **act** | proceed \| hold |
```

Credit the System One shape named in `NOTICE.md`. Do not claim a vendor call.
