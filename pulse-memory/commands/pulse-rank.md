---
description: Rank lived traces by whether they earned their keep; propose a prune list. Dry run. Deletes nothing.
argument-hint: optional --weekly, --as-of ISO, --days N
---

# /pulse-rank

Run `scripts/pulse_rank.py $ARGUMENTS`. Default JSON; `--weekly` prints the markdown report.

1. Observe: retrieve logs each hit as keys only.
2. Rank: score = 3·hits + restated + 4·locked + 2·supersedes + verified.
3. Tighten: propose `stale` then `idle` rows, at most `--max` (8).
4. Improve sparsely: a person prunes. The script never deletes.

`--record` appends the proposal to `archive_events`. Nothing else is written.
