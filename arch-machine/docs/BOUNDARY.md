# Core vs expandable boundary (arch-machine operator plugin)

Machine-readable source of truth: `../core-map.json`.

## Thin core (always preferred first)

| What | Why essential |
|------|----------------|
| `install.sh --thin` | Default first install; sentinel only |
| `tinfoil` binary on PATH | Audit + version + scriptable control |
| `/usr/share/tinfoil` or repo checkout | Runtime tree for scripts/config |
| `lib/`, `config/profiles/minimal.yaml` | Resolve profiles later without shipping all modules |

**Not core:** gum BubbleTea TUI (`tinfoil tui`), full `ml-dev` / `security-dev` profiles, GPU/ROCm, k8s stacks, optional modules under `modules/*`.

## Expandable (pull on demand, consent only)

| Tier | What `--yes` actually does |
|------|----------------------------|
| **Module** (e.g. `security`) | 1) `am_ensure_repo` — resolve or **clone** remote (`sentinel`) into `~/.cache/arch-machine/src` (or `ARCH_MACHINE_ROOT`). 2) Optional **pull**. 3) Run `modules/<name>/install.sh --agent-expand` when the hook exists (real module prep: e.g. security verifies keeper crate, writes `.agent-expanded`). 4) Write `.arch-expand-state/<name>.stamp`. |
| **Profile** (e.g. `ml-dev`) | After ensure repo: `tinfoil install --profile …` or `./install.sh --profile …` (heavy; never auto). |
| **Without `--yes`** | **Fail closed** (exit 2). Dry-run alone is not consent. |

- **Remote:** `https://github.com/p10ns11y/arch-machine` (`sentinel` branch)
- **Never** auto-expand full `ml-dev` / `security-dev` without explicit name + `--yes`
- Module `--agent-expand` is **not** full profile install (no k3s/sudo by default). Full stacks stay profile path.

## Agent-as-TUI (replaces tinfoil TUI as primary surface)

| Operator intent | Slash | Mutates? |
|-----------------|-------|----------|
| Health / PATH | `/arch-status` | No |
| Thin install / clone | `/arch-init` then `/arch-init --yes` | Yes (consent) |
| Audit | `/arch-audit` | No (read-only) |
| Expand module/profile | `/arch-expand …` then `--yes` | Yes (consent) |

`bin/am-*` are agent-internal. Operators use slash commands only (same pattern as premflow).

## FSD / unsupervised

Allowlist auto: status, version, audit, map, path-probe.  
Everything that installs or expands **fails closed** without `--yes`.

## Proof

```bash
./test/test-core-map.sh
./test/test-expand-consent.sh
./test/test-expand-real.sh   # --yes writes real markers (fixture, no dry-run)
```
