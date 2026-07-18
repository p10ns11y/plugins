# SCRATCH verification — arch-machine Grok plugin 2026-07-18T15:59:34+05:30

## Environment
- plugins source: ~/Work/personal/plugins/arch-machine (not ~/plugins)
- grok list: arch-machine-54fe4f7a enabled
- config.toml [plugins].enabled includes arch-machine

## Tests
=== core-map parse ===
ok default_install=thin
ok core.tier=thin
ok am_is_core_binary tinfoil
ok am_is_expandable security
ok am_is_expandable ml-dev
ok fail closed: am_is_expandable not-a-real-tier
=== FSD allowlist ===
ok am_fsd_allowed status
ok am_fsd_allowed audit
ok fail closed: am_fsd_allowed expand
ok am_requires_consent expand
ok am_requires_consent init
=== consent gate ===
ok expand without --yes exits 2
ok expand with --yes ok
ok init without --yes exits 2
ok am_fsd_allowed map
ok fail_closed
ok no isp ip trust
ok never auto full profile
ALL_UNIT_OK

=== launch 1: no consent ===
consent_required: expand 'security' needs --yes (fail closed)
=== launch 2: dry-run with consent ===
repo: /home/sustainableabundance/arch-machine
expand kind=module target=security
dry-run: would run module expand for security
dry-run: would execute: bash /home/sustainableabundance/arch-machine/modules/security/install.sh --agent-expand
=== launch 3: second dry-run consistent ===
repo: /home/sustainableabundance/arch-machine
expand kind=profile target=ml-dev
dry-run: would run install.sh --profile ml-dev (or tinfoil install --profile ml-dev)
=== unknown tier ===
EXPAND_CONSENT_OK

=== 1: --yes module expand (security fixture, NO dry-run) ===
repo: /home/sustainableabundance/Work/personal/plugins/arch-machine/fixtures/mock-arch
expand kind=module target=security
fixture agent-expand: security
wrote /home/sustainableabundance/Work/personal/plugins/arch-machine/fixtures/mock-arch/modules/security/expanded-out/result.txt
agent_expand_ok: security
module_expand_ok: security (via /home/sustainableabundance/Work/personal/plugins/arch-machine/fixtures/mock-arch/modules/security/install.sh --agent-expand)
stamp: /home/sustainableabundance/Work/personal/plugins/arch-machine/fixtures/mock-arch/.arch-expand-state/security.stamp
marker: /home/sustainableabundance/Work/personal/plugins/arch-machine/fixtures/mock-arch/modules/security/.agent-expanded
ok real side effects on disk
=== 2: fail closed still holds ===
ok fail closed
=== 3: module without --agent-expand hook still stamps (productivity) ===
repo: /home/sustainableabundance/Work/personal/plugins/arch-machine/fixtures/mock-arch
expand kind=module target=productivity
module_expand_ok: productivity (tree present; stamp+marker; no --agent-expand hook)
stamp: /home/sustainableabundance/Work/personal/plugins/arch-machine/fixtures/mock-arch/.arch-expand-state/productivity.stamp
marker: /home/sustainableabundance/Work/personal/plugins/arch-machine/fixtures/mock-arch/modules/productivity/.agent-expanded
ok stamp+marker path for hookless module
EXPAND_REAL_OK

## Live expand (real repo, no dry-run)
repo: /home/sustainableabundance/arch-machine
expand kind=module target=security
agent-expand: security module at /home/sustainableabundance/arch-machine/modules/security
wrote /home/sustainableabundance/arch-machine/modules/security/.agent-expanded
agent_expand_ok: security
module_expand_ok: security (via /home/sustainableabundance/arch-machine/modules/security/install.sh --agent-expand)
stamp: /home/sustainableabundance/arch-machine/.arch-expand-state/security.stamp
marker: /home/sustainableabundance/arch-machine/modules/security/.agent-expanded

stamp: 2026-07-18T15:59:34+05:30
marker: 2026-07-18T15:59:34+05:30

## Plugin enable
  arch-machine-54fe4f7a: arch-machine [local: /home/sustainableabundance/Work/personal/plugins/arch-machine]
    "arch-machine",

SCRATCH_OK
