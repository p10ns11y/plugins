# Layers

Expand only to place one invariant. Earlier layers beat later ones.

| id | Holds the invariant when | A miss looks like |
|---|---|---|
| `shape` | The wrong change is hard to represent. When Bend is installed, the claims are `trust-stack/bend/LAWS.bend` and the proof command is `bend PROOF.bend`. A passing proof does not retire `check`, `watch`, or `guide`. | The bug is legal code, and a person is asked to notice. |
| `check` | A compiler, typecheck, or static analyzer fails the build on this class of bug. | The agent says it looks right and nothing ran. |
| `watch` | A rule or a review bot flags it, and a coding agent fixes that finding. | A human is reading the diff to enforce a lint. |
| `skill` | The agent already failed this way once. The lesson is now a skill or a rule, not only a patch on one pull request. | The same workaround appears again next week. |
| `guide` | Only a person’s taste can hold it. Style that no checker can see. | Every invariant lives here. That is review land. |

## Contagion

The codebase is the memory. Agents copy the patterns they can see.

A local workaround spreads. A comment that excuses a real fix spreads faster, because the next agent treats the comment as permission. Delete the pattern. Put the invariant on `shape`, `check`, `watch`, or `skill`. Do not add a second comment.

## Fan-out

One owner agent takes a change from plan through the real check. Other agents may collect bugs and ideas. They do not edit that same change.

Do not spawn a crowd of writers until one agent is already trusted on this tree. An untrusted agent, copied a hundred times, is a hundred copies of the miss.

## Verify

Verification is the agent using the same surface a user has: the test, the trace, the running UI. A prose claim that it works is not a pass.

Volume is not the goal. The layers compound into trust. A count of pull requests is someone else’s outcome, not a target.
