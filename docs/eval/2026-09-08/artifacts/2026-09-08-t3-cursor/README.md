# mission-map Tier 3 with cursor-cli (2026-09-08)

Local Harbor plus `cursor-agent` (Harbor name `cursor-cli`) plus NVIDIA Build as the judge only. Agent model is `cursor/composer-2.5`. Docker was not used. The eval account is not in the `docker` group.

The runner is [NVIDIA SkillEvaluator](https://docs.nvidia.com/skills/skillevaluator/). Source is [NVIDIA/SkillEvaluator](https://github.com/NVIDIA/SkillEvaluator). To rerun, follow [How to verify](../../README.md#how-to-verify).

## What ran

`skillevaluator doctor --env-mode local --agents cursor-cli --agent-model cursor-cli=cursor/composer-2.5` passed. See [mission-map-t3-doctor.txt](mission-map-t3-doctor.txt).

Job `mission-map-t3.5yilgJ` ran 2522s and exited 1. Score coverage was 2/4. Published dimensions stay `NO SCORE`.

## Failures

`cursor-agent` started and finished trials. The NVIDIA judge timed out on `mission-map-explicit-replan` and `mission-map-implicit-deadline` for both with-skill and no-skill.

That is the same judge timeout that killed the OpenCode passes. Splitting the agent off NVIDIA did not fix the grader.

## Local-mode patches

`docs/eval/se_local_patch.py` now also:

- allowlists Harbor `cursor-cli` for local plus `nv_build`
- installs with `cursor-agent --version` only
- copies host `~/.config/cursor/auth.json` into the sandbox instead of stuffing a login token into `CURSOR_API_KEY`
- binds the cursor-agent package directory so the sandboxed `--version` probe can see its Node tree
- treats `cursor/*` models as degraded catalog probes so NVIDIA listing does not reject them

`prime-agent` has no Harbor adapter. Stay on `cursor-cli` for this path.
