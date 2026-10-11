# Card and log shapes

The checker owns these shapes. A skill sentence that restates them is not a second copy.

## Invariant card

Optional title line, exactly `# Invariant card`.

Each other non-blank line:

`- <one sentence>. Fails: \`<command>\``

One to seven such lines. The sentence ends at the period before `Fails:`. The command is the thing that fails when the sentence is wrong. `true`, `false`, `:`, and `exit 0` are refused. A feeling with no failing command is refused because it is not a card line.

## Steer log

Header, optional, exactly `| decision | why | verify |`.

Each data row:

`| <decision> | <why> | \`<command>\` |`

Decision and why are non-empty. The command follows the same no-op rule as a card. `log` writes the admitted bytes to `LOG.prior`. The next `log` admits only when those rows are still a prefix. An edited or deleted older row is refused. `log LOG --prior PRIOR` compares with that file instead, and still updates `LOG.prior` on admit. A new row goes at the end.

## Steering doc

Every non-blank line is a blockquote, `>` at the start. Any other line is refused, including a narrative that also contains one real quote. The text after `>` must be at least 12 characters and must appear inside the log file to count. A doc with no such line is refused. A shorter blockquote is ignored. A quote that is not in the log is refused.

## Pre-builder directory

`pre DIR` reads six files. The planner's own tests stay in that repo. This checker only refuses the bundle.

| File | Admit |
|------|--------|
| `interactions` | One or more commands that can fail. `impeccable`, `superdesign`, and `layout-content-view` are refused. |
| `verify` | Script text that mentions JSON and does not name a model client. |
| `prose` | No `demo`, `gate`, or `the owner`. At most 120 words. |
| `writers` | Exactly one non-empty line. |
| `invariant.md` | A card with exactly one line. |
| `host` | A `connector: \`<command>\`` line. The command can fail, and it does not carry a team id. The brief does not ask to add keys. |
