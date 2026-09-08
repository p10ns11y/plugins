# uncertainty-laws

**Napkin probability for foggy decisions** — not a forecast, not a tip sheet.

Four laws, in order: **expected value → base rates → variance/ruin → Kelly**.
Honest exits include **Wait**, **Park**, and **nothing you can do now**.

| Use this when | Skip when |
|---------------|-----------|
| Wealth / refinance / sell / insurance fog | Next act is one file + known verify |
| “Should I escalate / commit / bet?” | Pure scheduling of an already-chosen Do |
| Average returns or shiny win rates confuse you | You need a critical-path DAG → use **mission-map** first |

Slash: `/uncertainty-laws`.

---

## Surfaces (do not fuse them)

| Surface | Job | Invoke |
|---------|-----|--------|
| **Skill** | Run the four laws; emit honest exit | `/uncertainty-laws` or auto-match |
| **Plugin** | Bundle (skill + command + refs) | `grok plugin install uncertainty-laws --trust` |
| **mission-map** | Path / Do-Risk-Wait-Park | `/mission-map` then napkin the next fork |
| **eva-emptiness** | Blank priors | `/eva` when the map itself is missing |

---

## Mental model

```text
Law1 EV        is the price wrong in my favour?
Law2 base rate how common before this evidence?
Law3 ruin      can my one path hit absorbing zero?
Law4 Kelly     how big without deleting the edge?
```

You are **one path**, not the crowd average. Survival is the strategy.
Being right is not being paid. Oversize while being right still ruins you.

## Attribution

Four-law napkin framing inspired by **Venix** (@0xVenix):

- Article: [The Four Laws of Probability That Quietly Decide Who Keeps the Money](https://x.com/0xVenix/status/2095614241969520904)
- Status: https://x.com/0xVenix/status/2095614241969520904

The underlying formulas (expected value, Bayes, ruin/growth, Kelly) are classical.
This plugin is an **agent procedure**, not a copy of that article’s prose.

---

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin marketplace update
grok plugin install uncertainty-laws --trust
```

Dev tree:

```bash
ln -sfn "$HOME/Work/personal/plugins/uncertainty-laws" "$HOME/.grok/plugins/uncertainty-laws"
ln -sfn "$HOME/Work/personal/plugins/uncertainty-laws/skills/uncertainty-laws" "$HOME/.grok/skills/uncertainty-laws"
ln -sfn "$HOME/Work/personal/plugins/uncertainty-laws/skills/uncertainty-laws" "$HOME/.cursor/skills/uncertainty-laws"
```

Related: install **mission-map** for critical path, then chain:

```text
/mission-map   →  next Do / Risk
/uncertainty-laws  →  size or honest Wait
```

---

## Verify

```bash
./test/test-thin.sh
```

---

## Hard nos

- No PII, personnummer, employer names, or live debt amounts in emits or fixtures.
- No fake precision when inputs are vibes.
- No silent overwrite of mission-map bands.
