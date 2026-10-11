---
description: Harden Node dependencies. Loads security fixes, then upgrades, allowBuilds, and IDE dependency audits. Does not load supply-chain-harden.
argument-hint: the repo or the audit finding to harden
---

# /dependency-harden

Load skill **fix-dependency-security**, then **upgrade-packages**, **audit-allow-builds**, and **audit-ide-dependencies**. Do not load supply-chain-harden.

`$ARGUMENTS` is the repo or finding. If it is empty, use the current turn.
