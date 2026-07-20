# Core vs expandable boundary (arch-machine operator plugin)

Machine-readable source of truth: `../core-map.json`.

## Thin core (always preferred first)

| What | Why essential |
|------|----------------|
| `install.sh --thin` | Default first install; sentinel runtime |
| **archy** (`crates/archy`) | Main control plane (Ratatui, Eagle+TEA) |
| `tinfoil` binary (optional shim) | Thin CLI / legacy dispatch |
| `/usr/share/tinfoil` or repo checkout | Runtime tree for scripts/config |
| `maintenance/security-audit.sh` | Threat-focused host audit backend |
| `lib/`, `config/profiles/minimal.yaml` | Resolve profiles later without shipping all modules |

**Not core:** gum BubbleTea TUI (`tinfoil tui`), full `ml-dev` / `security-dev` profiles, GPU/ROCm, k8s stacks, optional modules under `modules/*`.

## Surfaces (priority)

1. **archy** interactive TUI (or `/arch-control`)
2. Agent slash commands (`/arch-status`, `/arch-audit`, …)
3. Shell backends (`maintenance/*.sh`)
4. **Last resort:** `tinfoil tui` gum legacy

**Cycle:** Grok plugin drives host via `/arch-*`; archy reopens Grok with preloaded job context (`G` / `p`). See [CROSS-REF.md](CROSS-REF.md).

## Expandable (pull on demand, consent only)

| Tier | What `--yes` actually does |
|------|----------------------------|
| **Module** (e.g. `security`) | 1) `am_ensure_repo` — resolve or **clone** remote (`sentinel`) into `~/.cache/arch-machine/src` (or `ARCH_MACHINE_ROOT`). 2) Optional **pull**. 3) Run `modules/<name>/install.sh --agent-expand` when the hook exists. 4) Write `.arch-expand-state/<name>.stamp`. |
| **Profile** (e.g. `ml-dev`) | After ensure repo: `tinfoil install --profile …` or `./install.sh --profile …` (heavy; never auto). |
| **Without `--yes`** | **Fail closed** (exit 2). Dry-run alone is not consent. |

- **Remote:** `https://github.com/p10ns11y/arch-machine` (`sentinel` branch by default)
- **Never** auto-expand full `ml-dev` / `security-dev` without explicit name + `--yes`
- Module `--agent-expand` is **not** full profile install

## Agent-as-TUI

| Operator intent | Slash | Mutates? |
|-----------------|-------|----------|
| Health / PATH / archy probe | `/arch-status` | No |
| Control plane locate/run | `/arch-control` | No / TTY run |
| Thin install / clone | `/arch-init` then `/arch-init --yes` | Yes (consent) |
| Audit (threat areas) | `/arch-audit` | No (read-only) |
| Expand module/profile | `/arch-expand …` then `--yes` | Yes (consent) |

`bin/am-*` are agent-internal. Operators use slash commands only.

## FSD / unsupervised

Allowlist auto: status, version, audit, map, path-probe, archy-print-root.  
Everything that installs or expands **fails closed** without `--yes`.

## Proof

```bash
./test/test-core-map.sh
./test/test-expand-consent.sh
./test/test-expand-real.sh
./test/test-audit-status.sh
```
