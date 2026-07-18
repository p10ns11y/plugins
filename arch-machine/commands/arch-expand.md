---
description: Expand optional profile or module (consent-gated; fail closed)
argument-hint: "<profile|module> [--yes] [--dry-run]"
---

# /arch-expand — pull non-core tiers

**User surface:** `/arch-expand security` · `/arch-expand security --yes` · `/arch-expand ml-dev --yes --dry-run`

## Policy

1. **Fail closed** without `--yes` (exit 2).
2. Never default to full `ml-dev` / `security-dev` without explicit name + consent.
3. Supervised: explain risk from `core-map.json`, then ask.
4. Dry-run allowed with `--yes --dry-run` to preview without full install when possible.

## Expandable targets (see core-map)

Profiles: `minimal`, `ml-dev`, `security-dev`  
Modules: `security`, `ml_ai`, `development`, `productivity`, `system`

## Agent

```bash
PLUGIN="${GROK_PLUGIN_ROOT:?}"
# Without --yes in $ARGUMENTS → am-expand fails closed
"$PLUGIN/bin/am-expand" $ARGUMENTS
```

| User | Result |
|------|--------|
| `/arch-expand security` | consent_required, exit 2 |
| `/arch-expand security --yes --dry-run` | print planned action (no stamp) |
| `/arch-expand security --yes` | ensure repo → `install.sh --agent-expand` → stamp + marker (real work) |
