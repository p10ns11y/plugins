# Core vs expandable boundary (arch-machine operator plugin)

## Thin core (always preferred first)

| What | Why essential |
|------|----------------|
| `install.sh --thin` | Default first install; sentinel only |
| `tinfoil` binary on PATH | Audit + version + scriptable control |
| `/usr/share/tinfoil` or repo checkout | Runtime tree for scripts/config |
| `lib/`, `config/profiles/minimal.yaml` | Resolve profiles later without shipping all modules |

**Not core:** gum BubbleTea TUI (`tinfoil tui`), full `ml-dev` / `security-dev` profiles, GPU/ROCm, k8s stacks, optional modules under `modules/*`.

## Expandable (pull on demand)

- **Profiles:** `minimal`, `ml-dev`, `security-dev` via `./install.sh --profile …` or `tinfoil install --profile …` **only with `--yes`**
- **Modules:** `security`, `ml_ai`, `development`, `productivity`, `system` — clone/update from remote if missing, then install with consent
- **Remote:** `https://github.com/p10ns11y/arch-machine` (`sentinel` branch)

## Agent-as-TUI (replaces tinfoil TUI as primary surface)

| Operator intent | Slash | Mutates? |
|-----------------|-------|----------|
| Health / PATH | `/arch-status` | No |
| Thin install / clone | `/arch-init` then `/arch-init --yes` | Yes (consent) |
| Audit | `/arch-audit` | No (read-only) |
| Expand module/profile | `/arch-expand …` then `--yes` | Yes (consent) |

## FSD / unsupervised

Allowlist auto: status, version, audit, map, path-probe.  
Everything that installs or expands **fails closed** without `--yes`.

Machine-readable source: `core-map.json` next to this file.
