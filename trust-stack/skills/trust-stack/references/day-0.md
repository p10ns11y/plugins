# Day-0 holds

Apply these three invariants before product code, on any project. They live in this plugin.

1. A side effect runs only from the user's latest message, behind one function and one failing test.
2. A narrative may quote only lines already admitted in a source file, and its pull request stays a draft until you have read it.
3. Auto-merge stops at a side effect, a visibility change, or a page about your judgment.

| Hold | Layer |
|---|---|
| A side effect runs only from the latest user message | `check` |
| A narrative quotes only lines already admitted in a source file | `guide` |
| Auto-merge stops at a side effect, a visibility change, or a page about judgment | `watch` |

A check that the payload is complete does not hold the side effect. The latest user message is the intent.
