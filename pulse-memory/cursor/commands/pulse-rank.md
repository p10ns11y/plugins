---
description: Rank lived traces by whether they earned their keep; propose a prune list. Dry run. Deletes nothing.
---

# /pulse-rank

Run `scripts/pulse_rank.py`, or `--weekly` for the markdown report. Same contract as the Grok command.

1. Observe: retrieve logs each hit as keys only.
2. Rank: score = 3·hits + restated + 4·locked + 2·supersedes + verified.
3. Tighten: propose `stale` then `idle` rows, at most 8.
4. Improve sparsely: a person prunes. The script never deletes.
