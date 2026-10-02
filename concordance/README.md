# concordance

Corroborates one closed decision, then emits a card.

| Field | Meaning |
|---|---|
| `label_dm` | Closed label from the decision model. |
| `label_llm` | Closed label from the LLM. |
| `agree` | `yes` when the two tokens are the same. |
| `p_dm` | The decision model's number, unscaled. |
| `kappa_window` | Optional Cohen's kappa over recent cases. Empty when no window was supplied. |
| `act` | `proceed` or `hold`. |

proceed only when agree is yes and p_dm >= tau. `tau` is the caller's number. `hold` is the odd case, and intelli-route routes the hold. This plugin does not pick the route.

intelli-route loads this skill when the goal is a closed decision that must be corroborated. split-machine still places the machine. trust-stack still picks the layer and may point at this check.

## Install

```bash
grok plugin install ./concordance --trust
# slash: /concordance
```

## Tests

```bash
./concordance/test/test-thin.sh
```

Sources and the System One credit: [NOTICE.md](NOTICE.md).
