# cos (CoS)

**Process workflow for coordinating work** — not a bot, not a second chat persona, not part of flowingstack.

One live context, few specialists, verify before irreversible acts, then recover.

Slash: `/cos`.

## Process

```mermaid
flowchart LR
  Context[Name live context] --> Mode[Pick mode]
  Mode --> Flow[Route skills]
  Flow --> Verify[Verify before irreversible]
  Verify --> Act[Act or pause]
  Act --> Recover[Recover and compact]
```

| Use this when | Skip when |
|---------------|-----------|
| Non-trivial or multi-step work | One short reply with no extra help |
| A turn would fan out many specialists | Pure maintenance in rest mode |

---

## Install

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin marketplace update
grok plugin install cos --trust
```

---

## Verify

```bash
./test/test-thin.sh
```
