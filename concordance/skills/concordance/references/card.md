# Card log

Open this file only to append one line. The skill owns `proceed` and `hold`.

Append only when the caller named a log path. One case, one line. Do not rewrite an earlier line. If the caller named no path, skip the log and still emit the card.

```text
label_dm=<token> label_llm=<token> p_dm=<number> tau=<number> agree=<yes|no> act=<proceed|hold>
```

Write the tokens and numbers as given. Do not rescale `p_dm` or `tau`.

`kappa_window` is not on the line. When the caller supplies a window of recent cases, Cohen's kappa on that window is `(observed agreement - chance agreement) / (1 - chance agreement)`. Leave `kappa_window` empty when no window was supplied. Do not invent the counts. Kappa does not change `act`.
