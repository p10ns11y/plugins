# odysseus-navigator

**Faster intelli core-nailer** — judgment plane over **control-graph** (Outer) and **eva-emptiness** (Inner).

Judgment only. Outer stays in **control-graph**. Blank-sheet Inner stays in **eva-emptiness**. This plugin does **not** copy those rituals.

```text
  /odysseus-core   one bottleneck, one mistake, one next   ← default, fastest
  /odysseus        full Navigator table                     ← when several smells
  /eva             Prior→Probe→Simulate→Score→ActOrAsk      ← emptiness only
  /mission-map     heading û_G / PERT                       ← path math only
```

## Odysseus (this harness)

| Field | Value |
|-------|--------|
| **ithaca** | Nail the deepest bottleneck in one pass; then hook the owner that already runs the graph |
| **waters** | novel-pressure for the *fast path*; calm for C/Rhai/tether — refuse those |
| **mistakes we refuse** | Circe (golden-cage plugin), Sirens (new “intelli OS”), Scylla (skill XOR plugin), Winds (always-on hooks) |
| **antidotes** | YAGNI · Incremental (this tree is the bundled plugin) |
| **spirit** | Ithaca always; Metis only for the core-nailer shape |
| **cg_hook** | skip unless `/odysseus*` says multi-step |
| **eva_hook** | skip unless ≥2 emptiness signals |

## Do not ship (EVA / arch-machine / mission-map already own these)

| Refuse | Owner |
|--------|--------|
| C auth tether, PreToolUse hooks | `eva-emptiness` |
| Rhai background workflow | `eva-emptiness` / `arch-machine` |
| Three prior-fork agents | `eva-emptiness` Simulate |
| PERT / Monte-Carlo / Rust DAG | `mission-map` |
| `alwaysApply: true` lecture hook | — (Winds) |

## Install

Skill is **bundled** in `skills/odysseus-navigator/` (no symlink required).

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install odysseus-navigator --trust
# or local:
grok plugin install ./odysseus-navigator --trust
```

Dev symlink:

```bash
mkdir -p ~/.grok/plugins
ln -sfn "$(pwd)/odysseus-navigator" ~/.grok/plugins/odysseus-navigator
```

Cursor: copy `cursor/commands/*.md` into the project or user commands dir.

## Slash commands

| Command | Job |
|---------|-----|
| `/odysseus-core` | Deep core: Ithaca + **one** bottleneck + at most one mistake + one next |
| `/odysseus` | Full Navigator (all matching mistakes) when several smells |

`$ARGUMENTS` = goal / plan / dump. If empty, ask one sentence for Ithaca, then continue.

## Tests

```bash
./test/test-thin.sh
```

## Layout

```text
plugin.json
commands/           # Grok slash
cursor/commands/    # Cursor slash (same contract, no Grok $ARGUMENTS)
agents/             # one Navigator persona — not three priors
skills/odysseus-navigator/   # bundled procedure SoT
test/test-thin.sh   # refuse C / Rhai / hooks / prior circus
```
