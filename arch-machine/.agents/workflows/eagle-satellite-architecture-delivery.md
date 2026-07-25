---
name: eagle-satellite-architecture-delivery
description: end-to-end flow from plan approval through FSM implementation, skill extraction, doc updates and push
kind: workflow
skill_chain: ["eagle-satellite-elomaxz", "threat-first-audit-rewrite"]
---

# eagle-satellite-architecture-delivery

end-to-end flow from plan approval through FSM implementation, skill extraction, doc updates and push

## Skill chain

1. `eagle-satellite-elomaxz`
2. `threat-first-audit-rewrite`

## Phases

### Plan

incorporate xstate DAGs and Eagle+Satellites registry

### Implement

rewrite app.rs, add state transitions, satellite jobs

### Document

plain-English mermaid diagrams + new architecture skill

### Verify

dry-run, UI fixes, logical commits, push

## Support

- sessions: 1
- rank: 29
