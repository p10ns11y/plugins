---
name: dependency-harden
description: >-
  Portable Node supply-chain hardening: audit/fix vulns, workspace harden,
  safe upgrades, allowBuilds audit. Real skills only.
kind: workflow
skill_chain:
  - fix-dependency-security
  - fix-dependency-security
  - upgrade-packages
  - audit-allow-builds
---

# dependency-harden

## Skill chain

1. `fix-dependency-security`  
2. `fix-dependency-security`  
3. `upgrade-packages`  
4. `audit-allow-builds`  

## Phases

Explore (audit) → Fix vulns/deprecations → Harden workspace/sfw → Safe upgrades → allowBuilds audit → report

Replaces archived distill workflow `dependency-security-hardening` (stub skill_chain).
