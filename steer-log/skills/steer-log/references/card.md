# Card and log shapes

The checker owns these shapes. A skill sentence that restates them is not a second copy.

## Invariant card

Optional title line, exactly `# Invariant card`.

Each other non-blank line:

`- <one sentence>. Fails: \`<command>\``

One to seven such lines. The sentence ends at the period before `Fails:`. The command is the thing that fails when the sentence is wrong. `true`, `false`, `:`, and `exit 0` are refused. A feeling with no failing command is refused because it is not a card line.

## Steer log

Append-only. Header, optional, exactly `| decision | why | verify |`.

Each data row:

`| <decision> | <why> | \`<command>\` |`

Decision and why are non-empty. The command follows the same no-op rule as a card. Do not edit a row that is already in the file. Add a row.

## Steering doc

The only quote that counts is a blockquote line, `>` at the start. The text after `>` must be at least 12 characters and must appear inside the log file. A doc with no such line is refused. A shorter blockquote is ignored. A quote that is not in the log is refused.
