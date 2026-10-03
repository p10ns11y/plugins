# posting-check

Is a job posting still open? Deterministic, no LLM, Python 3 stdlib only. JSON to stdout.

## Call

```sh
P=ops/posting-check/posting_check.py
$P https://jobs.example.com/org/role-id
$P URL1 URL2 ...
$P -f urls.txt
cat urls.txt | $P
```

Exit 0 whenever it ran (a failed URL becomes `status: unknown` with the reason). Exit 2 on usage errors.

## Output

One object per URL, in input order:

| Field | Value |
|---|---|
| url | the input URL |
| ats | ashby, greenhouse, lever, teamtailor, workday, platsbanken, unknown |
| status | open, closed, unknown |
| posted_date | `YYYY-MM-DD` when available; else null |
| evidence | HTTP status plus the field or text that decided it |
| checked_at | UTC, `YYYY-MM-DDTHH:MM:SSZ` |

## Why it belongs here

Lauren Tan described agents rebuilding verification glue on every run (~24:00). A script like this is the deterministic half: every agent calls the same tool and gets the same JSON. The skill keeps judgment (when to check, what to do with closed rows); the script keeps the fetch and parse.

List it in your scripts index with path, purpose, and one example invocation.
