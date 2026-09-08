# mission-map Tier 3 (2026-09-08)

Local Harbor plus OpenCode 1.1.35 plus NVIDIA Build. Docker was not used. This user is not in the `docker` group, so `/var/run/docker.sock` is not writable.

The runner is [NVIDIA SkillEvaluator](https://docs.nvidia.com/skills/skillevaluator/). Source is [NVIDIA/SkillEvaluator](https://github.com/NVIDIA/SkillEvaluator). To rerun this pass, follow [How to verify](../../README.md#how-to-verify).

## What ran

`skillevaluator doctor --env-mode local --agents opencode` passed. See [mission-map-t3-doctor.txt](mission-map-t3-doctor.txt).

The dataset in `mission-map/skills/mission-map/evals/evals.json` is four organic cases. LLM `create-eval-dataset --full` fell back to description-echo templates. Those cases cannot measure skill lift.

## First evaluate

Concurrency 4, 300s agent timeout. OpenCode started after Harbor's `--thinking` flag was stripped. Score coverage was 0/4.

Failures:

- HTTP 429 on the NVIDIA judge
- judge read timeouts
- `AgentTimeoutError` at 300s on no-skill trials
- exit 140 on `mission-map-explicit-replan`

## Serialized rerun

`docs/eval/run-t2-t3.sh` now passes `--n-concurrent 1` and `--timeout-multiplier 2`. That run was still in progress when this file was written. With-skill finished 4 of 4 (2 errored). No-skill had finished 3 of 4.

## Local-mode patches

`docs/eval/se_local_patch.py` (loaded via a venv `.pth`):

- drops empty `BASH_ENV=""` resets so Harbor local exec does not reject the key
- strips `--thinking` from OpenCode 1.1.35

Copy the skill onto tmpfs before evaluate. Harbor `copytree_secure` holds a directory fd, then `scandir(fd)`. New names are invisible on btrfs.

`cursor-cli`, `grok`, and `prime-agent` are not on [SkillEvaluator](https://docs.nvidia.com/skills/skillevaluator/) 0.2.1 `nv_build` plus local allowlists. Stay on OpenCode until that changes.
