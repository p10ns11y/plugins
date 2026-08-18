# mission-map

A **Mission: Impossible briefing**, not a future oracle.

You name a checkable arrival \(G\), the facts \(x\), and a DAG of stages. The plugin
marks the **critical path**, one **next Do**, and (when you ask) the **heading**
toward \(G\) — \(\hat{u}_G\) and \(\cos\theta\). It does **not** tell you what
will happen.

| Use this when | Skip when |
|---------------|-----------|
| You need what / how / when under uncertainty | The next act is one file and a known verify command |
| Outside shocks will hit (rejects, illness, shiny detours) | You want a calendar destiny date |
| You want calculated risk and a replan rule | You want a 7-nines forecast |

Slash: `/mission-map`. Skill also matches “mission map”, “calculated risk”, “replan”.

---

## Surfaces (do not fuse them)

| Surface | Job | Invoke |
|---------|-----|--------|
| **Skill** | Procedure: name \(G\), DAG, classes, signposts | `/mission-map` or auto-match |
| **Plugin** | Bundle (skill + command + kernels) | `grok plugin install mission-map --trust` |
| **C `mm-kern`** | Leaf math only: PERT \(t_e\), MC, \(d t_e/d m\) | `bin/mm-kern pert 2 4 8` |
| **Rust `mission-map-graph`** | DAG, critical path, heading, mermaid, compare | `mission-map-graph map.json --mermaid` |
| **Nightly script** | Rewrite a vault page from the live JSON | `mm-lifeos-graph` + 20:00 user timer |

C does not own graphs. Rust does not own forecasts. The LLM may **propose** a
missing stage or band; a human **confirms**. Never silent \(a/m/b\) overwrite.

Personal live maps stay **off this repo** (`~/.grok/mission-maps/`).

---

## Mental model

```text
G          checkable arrival          e.g. "started a decent SE/EU FT role"
x          named facts now            no PII dumps
û_G        remaining critical path    thick arrows on the mermaid
∇T         d(te)/d(m) = 4/6           which week of mode moves arrival
cosθ       1 on-path · 0 Park · empty Wait
horizon X  long filter (e.g. SpaceXAI)   not a second sink
```

| Class | Meaning | This tick |
|-------|---------|-----------|
| **Do** | On the path; you can start it | Schedule hours |
| **Risk** | Blast × how soon it can fire | Mitigate or watch |
| **Wait** | Blocked on someone else or a date | Signpost only |
| **Park** | Slack / distraction (\(\nabla T \approx 0\)) | Refuse |
| **Done** | Finished; \(t_e = 0\) | Keep for topology |

**Bands, not dates.** Print optimistic / typical / pessimistic \(a / m / b\).
PERT: \(t_e = (a + 4m + b) / 6\).

On shock: do not add a new project. Re-run the remaining DAG only.

---

## Install

### 1. Plugin (always)

```bash
grok plugin marketplace add https://github.com/p10ns11y/plugins.git
grok plugin install mission-map --trust
```

Dev tree:

```bash
ln -sfn "$HOME/Work/personal/plugins/mission-map" "$HOME/.grok/plugins/mission-map"
ln -sfn "$HOME/Work/personal/plugins/mission-map/skills/mission-map" "$HOME/.grok/skills/mission-map"
ln -sfn "$HOME/Work/personal/plugins/mission-map/skills/mission-map" "$HOME/.cursor/skills/mission-map"
```

Reload Grok (`r` in `/plugins`). `/mission-map` works **without** compiling anything.

### 2. Kernels (optional — when you want numbers)

Needs: C11 `cc`, Rust `cargo`. No sudo. No network.

```bash
make -C c test                         # → bin/mm-kern (gitignored build)
cd rust && cargo test
cargo run -- ../examples/sample-map.json --mermaid
```

Consent pattern is the same as EVA tether: do not compile on a machine you do
not own the risk for. The skill still works as a briefing if the binaries are
missing.

### 3. Nightly vault graph (optional — 20:00 local)

Waybar chip (optional): `custom/mission-map` exec `mm-waybar` (signal 12). Click = notify with mail/URL; right-click = open `contacts.md`. Survives only in `~/.config/waybar/` — re-add after `omarchy refresh waybar`.

Grok `/loop` is **interval-only** and expires in 7 days. It cannot hit 20:00.
Use the user systemd timer (same pattern as north-star nudge).

```bash
scripts/mm-sync-collab-finder   # local pipeline + contact URLs from CF sqlite
chmod +x scripts/mm-lifeos-graph
ln -sfn "$(pwd)/scripts/mm-lifeos-graph" "$HOME/.local/bin/mm-lifeos-graph"
cp host/systemd/mission-map-graph.{service,timer} "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now mission-map-graph.timer
mm-lifeos-graph                        # seed ~/life-os/UI/Mission.md
systemctl --user list-timers mission-map-graph.timer
```

The timer reads `~/.grok/mission-maps/cash-path-now.json` and rewrites
`~/life-os/UI/Mission.md`. Override with `MISSION_MAPS`, `LIFEOS`,
`MISSION_MAP_NOW`, `MISSION_MAP_OUT`.

---

## Use cases

Pick the **smallest** row that answers the question. Do not start at critical.

### 1. Simple — one briefing, no files

**When:** You need a what / how / when list today. No JSON, no compile.

In Grok or Cursor:

```text
/mission-map  <one sentence G>
```

The agent fills:

1. \(G\) — one checkable arrival (not a tourist trip, not a new side app).
2. \(x\) — current facts only.
3. DAG — stages with **Do / Risk / Wait / Park**.
4. \(a/m/b\) bands (or a hard deadline on a stage).
5. One **next Do**. Hours only on high \(\partial T / \partial u\).
6. Signposts: `watch` → `fires_when` → `continue | switch | Ask`.

**Done when:** one \(G\), one critical path, one next Do, every Risk has a
signpost, Parks are named so you can refuse them.

Example prompt:

```text
/mission-map  G is "shipped v1 of the billing API". x: two engineers, Friday
freeze, vendor SLA unknown. Replan if the vendor slips.
```

### 2. Everyday — JSON map + heading picture

**When:** The briefing is recurring and you want \(\hat{u}_G\) drawn.

Copy `examples/sample-map.json` to a **personal** path (not this repo):

```json
{
  "g": "started a decent full-time role",
  "stages": [
    { "id": "pack", "a": 0.5, "m": 1, "b": 2, "depends_on": [], "class": "Do", "what": "apply pack" },
    { "id": "interview", "a": 2, "m": 4, "b": 8, "depends_on": ["pack"], "class": "Wait" },
    { "id": "start", "a": 1, "m": 3, "b": 8, "depends_on": ["interview"], "class": "Wait" },
    { "id": "side-project", "a": 2, "m": 4, "b": 8, "depends_on": [], "class": "Park" }
  ]
}
```

```bash
cd rust && cargo run --quiet -- /path/to/map.json --mermaid
```

You get:

```text
g=started a decent full-time role
critical=pack -> interview -> start
path_te=8.916667
next_do=pack
heading=on-path
cos=1
residual=pack -> interview -> start -> G
parked=side-project
--- mermaid
flowchart TB
  ...
```

| heading | \(\cos\theta\) | Meaning |
|---------|----------------|---------|
| `on-path` | `1` | Next Do sits on remaining \(\hat{u}_G\) |
| `wait` | empty | No self-vector; do not invent work |
| `park` | `0` | Orthogonal — refuse this tick |

Mark a finished stage `"class": "Done"`. It stays for edges; \(t_e\) becomes 0;
`next_do` skips it.

### 3. Recurring — how far since last week / last night

**When:** You want movement, not a new project.

Keep two snapshots (both personal):

```bash
mission-map-graph now.json --compare then.json --mermaid
```

| Field | Read as |
|-------|---------|
| `delta_te < 0` | Remaining expected weeks shrank (progress) |
| `delta_te > 0` | Remaining \(T\) grew — new Wait or a longer band |
| `completed=` | Stages that flipped to **Done** since `then` |

Nightly `mm-lifeos-graph` does this against `cash-path-last-run.json` and
classifies the vault page as **on-path / wait / deviation**. Deviation fires a
desktop notify when \(\cos\theta = 0\) or remaining \(T\) grew.

Do **not** treat `path_te` as a start date. It is a band, in the same unit you
put in \(a/m/b\) (usually weeks).

### 4. Complex — several missions, effort cap, shocks

**When:** Cash path, a product ship, and a family energy cap share one week.

Rules:

- One map per \(G\). Do not merge two arrivals into one DAG.
- `effort_cap` is hours you will actually keep, not a wish.
- Put hours only on **Do** nodes on the critical path.
- Parallel **Do** that is not on the longest chain is slack unless it feeds
  the sink (then it can be `next_do`).
- Each outside shock gets one signpost. When it fires: `continue`, `switch`,
  or **Ask** — then re-run the **remaining** DAG only.

Worked schema (skill + optional markdown brief):

```text
G            checkable arrival
x            named facts (no PII)
stages[]     id, what, how, a, m, b, deadline?, owner, class, depends_on[]
critical     longest expected chain
next_do      first Do on remaining critical, else first Do
heading      on-path | wait | park
signposts[]  watch, fires_when, then ∈ {continue, switch, Ask}
effort_cap   hours/week you will keep
```

Leaf math when the DAG is stable:

```bash
mm-kern pert 2 4 8          # te and sigma for one stage
mm-kern grad 2 4 8          # d(te)/d(m) = 4/6
mm-kern mc 2 4 8 1 3 5      # path mean / p50 / p90
```

\(\nabla T\) ranks **which lever moves arrival**. It is not a bearing toward
the north star. Horizon \(X\) (a long filter) is **not** a second \(G\).

### 5. Critical — irreversible, cash, or auth-hard

**When:** A wrong tick costs money, legal standing, or a burned intro.

| Gate | Do | Do not |
|------|----|--------|
| Human confirms every new stage / band | Propose in chat | Silent formula rewrite |
| One next Do | Wait if the path is calendars | Invent extra apps that week |
| Parks named | Refuse GTK / second inbox / dead resend | “Just a small side tool” |
| Live JSON off git | `~/.grok/mission-maps/` | Commit employer names, tickets, amounts |
| Compile C / mutate params | Same consent as `/eva-tether-init --yes` | Build kernels on a shared box “to see” |
| Shock | Replan remaining DAG | Add a new project to feel busy |
| Vault nightly | Display + \(\cos\theta\) | Let the timer edit \(a/m/b\) |

If the map itself is missing (rumors only, futures disagree), stop and use
**eva-emptiness** (`/eva`) — emptiness owns the blank sheet. This plugin owns
the map **after** \(G\) is nameable.

Pair with `north-star-compass` for *which slot is live*. Slot 3 = close laptop.
Do not build a new overlay; Walker is the picker.

---

## CLI

```text
mission-map-graph <map.json> [--mermaid] [--compare <then.json>]
mm-kern pert <a> <m> <b>
mm-kern mc   <a> <m> <b> [<a> <m> <b> ...]
mm-kern grad <a> <m> <b>
mm-lifeos-graph
```

Times are in the unit you pass. Constraints: \(a \ge 0\), \(a \le m \le b\).
Max 32 stages.

```bash
make -C c test
cd rust && cargo test
./test/test-kern.sh
./test/test-lifeos-graph.sh
```

---

## Layout

```text
commands/mission-map.md          /mission-map
skills/mission-map/SKILL.md      procedure
skills/mission-map/references/   map-schema.md · kernels.md
examples/sample-map.json         fixture (not a live life)
c/                               PERT / MC / grad (C11)
rust/                            DAG + heading + mermaid
scripts/mm-lifeos-graph          nightly vault rewrite
host/systemd/                    20:00 user timer units
```

Later kernel (not this tree): finite-diff \(\nabla T\) on a free state vector.
Still not a forecast.

---

## Related

`control-graph` · `eva-emptiness` · `north-star-compass`
