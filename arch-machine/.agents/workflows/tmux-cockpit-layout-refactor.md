---
name: tmux-cockpit-layout-refactor
description: End-to-end redesign of verify/test cockpits, alias hygiene, test prioritization, and PR review closure
kind: workflow
skill_chain: ["tmux-layout-swap", "remove-redundant-cd-prefix", "alias-reload-conflict-fix", "priority-test-manifest"]
---

# tmux-cockpit-layout-refactor

End-to-end redesign of verify/test cockpits, alias hygiene, test prioritization, and PR review closure

## Skill chain

1. `tmux-layout-swap`
2. `remove-redundant-cd-prefix`
3. `alias-reload-conflict-fix`
4. `priority-test-manifest`

## Phases

### Explore

Grep/Read layout and launch scripts

### Implement

Write/StrReplace new layout and manifest

### Verify

Shell tests + drift check

### Review

fusion-sage + pr-review-canvas on branch

## Support

- sessions: 1
- rank: 29
