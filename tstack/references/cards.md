# Capture card

Skills point here and do not restate the fields.

One shape for every connector. A human stop is the same card with a stop kind.

```text
# Card
- kind: none | money | send | sign
- source: mail | calendar | pr | chat
- ask: <one sentence>
- deadline: none | YYYY-MM-DD
- holds: none | pay | send | sign
- owner: none | si
- ref: none | mail:N | calendar:N | pr:N | chat:N
```

Rules the script enforces:

- Lines stay in that order, under the title `# Card`.
- `kind: none` requires `holds: none` and `owner: none`.
- `kind: money` requires `holds: pay` and `owner: si`.
- `kind: send` requires `holds: send` and `owner: si`. Kind `send` means sending.
- `kind: sign` requires `holds: sign` and `owner: si`. Kind `sign` means signing.
- `ask` matches `^[A-Za-z][A-Za-z ]*\.$`, length 2 to 120, and contains neither `@` nor `http` in any case.
- `deadline` is `none` or `YYYY-MM-DD`. The pattern does not check that the month is 1–12.
- `ref` is `none` or `<source>:<1-6 digits>`, and the prefix equals `source`.
- A record that breaks a rule exits 2 and prints no card. The script does not rewrite a lie into a legal card.
- `ask` is never a subject, a body, or a pull-request title. Constants when the source text is not already a clean sentence: mail `A thread needs a look.` Calendar `A calendar block changed.` Chat `A chat needs a look.` Pull request `A pull request is waiting.`
