# Admissions (expand only if SKILL.md is ambiguous)

Essays (canonical prose; this file is the operational extract):

- Pulse / traffic: https://captain.kingsparrow.space/focus/memory-issue
- Archive / admissions: https://captain.kingsparrow.space/focus/memory-issue/archive-not-memory

## Four kinds (form is not memory; reuse is)

| Kind | Meaning | Live path? |
|------|---------|------------|
| data | what existed; may never move an outcome | no (archive) |
| context | what is loaded now | already in window |
| fact | treated as currently true; still may not change a decision | only if admissions pass |
| memory | past trace kept because it should change a **later** action | yes, as pulse |

## Locks (harness)

- Write only after a check. Generated sentence = hypothesis until tagged.
- Raw logs = archive. Summaries = cheap index. If the summary cannot justify the next action, escalate to the log and write back only the grounded slice.
- Split **belief** (user-stated, possibly wrong) from **locked** (tool-verified or user-locked). Do not retrieve a misconception without its correction.
- Relevance ≠ still in force. Supersession is a different signal from nearness.
- Allow “not in the evidence.” If abstention is illegal, the model fills and the fill gets saved.
- Provenance, edit, and delete are part of truthfulness.

## Pulse packet (traffic)

```text
retrieval key
verification flag   # inject only if fragment still hashes to the locked revision
prefetch            # next likely key, warming
snippet             # ~120 verified tokens, not a dump
```

Dumping grows *n* in the wrong direction (noise, heat, lost-in-the-middle). Pulse keeps the working set small and barriers high.
