---
name: tomato-loop
description: One focus block on one Do. Energy check, premflow pomodoro, evidence, replan. Engineering lane picks by impact and hands repo work to pstack-map.
---

# tomato-loop

## Loop

1. Energy check: high, mid or low. Low picks the shortest Do.
Record the open block with tstack-state as in references/state.md, and pass the plan text. If premflow is missing, bin/premflow-path prints one line that points at premflow/README.md and the block still opens.
2. Load **mission-map**. Take the top Do on the critical path. Park is not work.
3. Load **intelli-route**. Repo work goes to **pstack-map**. A closed decision goes to **concordance**; `hold` becomes a HITL card.
4. Start the block. Never wait on the timer in the agent shell; it is not a TTY.
   - Preferred: `/focus <plan> <context>` from **premflow**.
   - Paste-ready: `premflow pomo <plan> <context>`, e.g. `premflow pomo 25 draft cover note` or `premflow pomo 20,4,20,4 deep work`.
   - Stop: press `q` in the block's terminal. Pause `space`, restart segment `r`, reset plan `R`. The CLI has no stop subcommand.
   - On block end premflow writes a `[POMO]` row to its ledger.
5. Send, pay, sign or anything irreversible: stop and raise a HITL card.
6. Load **harvest**, then return to step 1.

Open work goes in with `premflow task add <text>`; closing it is `premflow task done <n>`. Read with `premflow task list` or `premflow review`.

## Engineering lane

- Pick: **mission-map** ranks by impact; the top repo Do goes to **pstack-map** for handoff.
- Area reviews: one area per block on a schedule; **michelin-kitchen** keeps the prep.
- Long work: **steer-log** time-boxes it; **steer-accel** records the earn. Over the box, steer or stop.
- Merge check: `tstack/bin/merge-check --repo <dir> --tests-exit <n> --writer-family <token> --reviewer-family <token>`. Proceed only when the exit is 0, the reviewer token is a different model family from the writer token, and `<dir>/FREEZE` is absent. Otherwise hold. Concordance does not run this check.
- Weekly pruning: drop unused skills. Keep the ones the owner still runs.
- Invariants go on the earliest layer: **trust-stack**. SI owns the write: **si**.
