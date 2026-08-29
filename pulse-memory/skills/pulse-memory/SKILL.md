---
name: pulse-memory
description: >
  Resolve conflicts and contradictions in notes, memory, and harness state
  using admissions rules (archive vs memory). Always stamp context-hint tags
  (source, time, status, kind). Pulse sparse snippets instead of dumping
  transcripts. Use when claims disagree, a story was completed under pressure,
  the user says pulse / admissions / context tags / archive-not-memory, or runs
  /pulse-memory. Essays: captain.kingsparrow.space/focus/memory-issue
  and /archive-not-memory.
---

# pulse-memory

> **Load rule:** This file is the **filter plane**. Expand [references/usecases.md](references/usecases.md) for modes / `thinking_path` / `harness_path` / `as_of`. Expand [references/admissions.md](references/admissions.md) only if a tag or conflict rule is still ambiguous. Store: [references/store.md](references/store.md). Do not paste the essays.

```text
Archive  : residue (logs, tickets, embeddings, full transcripts)
Memory   : a past trace kept only because it is expected to change the next action
Pulse    : sparse retrieval → surgical snippet (not a dump)
Hint     : source · time · status · kind  // required on every claim you write or inject
Status   ∈ { user-stated, tool-verified, inferred, unknown }
Kind     ∈ { data, context, fact, memory }
```

**Axioms**

1. The archive may be large. What enters the live path stays **sparse, dated, sourced, incomplete-ok**.
2. Admissions test: *would this trace change the next action enough to justify bringing it back?* If no → archive, do not inject.
3. Never average conflicting traces into one fluent story. Tag both; prefer **later + higher status**; else **not in the evidence**.
4. Every sentence you promote to memory **must** carry hint tags. Untagged write = hypothesis, not memory.
5. Abstention is legal. If you cannot tag it, do not save it.

Sources (do not copy bodies): [Pulse instead of dump](https://captain.kingsparrow.space/focus/memory-issue) · [Archive is not memory](https://captain.kingsparrow.space/focus/memory-issue/archive-not-memory)

---

## When to use

- Two notes, memories, or tool results **contradict**
- User asks to tag, pulse, admit, or clean a dump
- Writing session/career/memory files that will be retrieved later
- `/pulse-memory` (turn) · `/workflow pulse-memory` (`mode`: `both` \| `thinking` \| `harness`)

Skip: one-file typo with no claims about the past. Former name: `archive-not-memory` (alias skill redirects here).

**Workflow args (file modes):** `as_of` always (ISO-8601). `thinking_path` if mode is `both`/`thinking`. `harness_path` if `both`/`harness`. `next_action` recommended. Examples: [references/usecases.md](references/usecases.md).

---

## Always stamp (hint tags)

```text
hint:
  source: <path | url | user | tool:name | imagined | told-later>
  time:   <ISO-8601 or "unknown">
  status: user-stated | tool-verified | inferred | unknown
  kind:   data | context | fact | memory
  lock:   open | locked
```

Status rank: `tool-verified` > `user-stated` > `inferred` > `unknown`.  
**Freshness over similarity.** A later `user-stated` revocation beats an older similar “fact.”

---

## Resolve conflicts / contradictions

1. Extract each claim. Untagged → tag now (`status: unknown` if unknown).
2. Same subject, incompatible predicates → **conflict set**, do not merge.
3. Compare `time` then `status`. Winner must still pass admissions for *this* next action.
4. If tied or evidence missing: **not in the evidence**; keep both in archive.
5. Never promote an inferred fill to `locked`.

Pulse shape (body ≤ ~120 tokens):

```text
pulse:
  key:     <retrieval key>
  verify:  <hash or "none">
  prefetch:<next likely key or "none">
  snippet: <surgical text>
  hint:    { source, time, status, kind, lock }
```

---

## Done when

- [ ] Every injected or written claim has hint tags
- [ ] Conflicts listed, not averaged
- [ ] Snippets are pulses; full logs stay archive
- [ ] “Not in the evidence” used when the filter fails

**Do not:** dump transcripts; invent completeness; save fluent lies as locked truth.
