# SkillEvaluator pass — mission-map — 2026-09-08

Companion to `p10ns11y/skills` `docs/eval/2026-09-08/`. Same wave evaluated plugin skill [`mission-map`](../../mission-map/skills/mission-map/). The runner is [NVIDIA SkillEvaluator](https://docs.nvidia.com/skills/skillevaluator/). Source is [NVIDIA/SkillEvaluator](https://github.com/NVIDIA/SkillEvaluator).

## Results

| Target | Grade | Score /100 | Notes |
|--------|-------|------------|-------|
| mission-map (plugin skill) | **A** | **100.0** | `quality-check` PASS. `validate --tiers 1,2` **12/12 PASS**. |

Tier 1 is 11/11 PASS. Security scan completes when SKILL.md has no unresolved local path-like refs (`bin/mm-kern`, `C/Rust`). SkillSpector then reports LOW/SAFE instead of fail-closed CAUTION.

Tier 2 Context Deduplication is PASS. Three files, 14 chunks, no duplicate guidance. Runtime was 47s on NVIDIA `nemotron-3-embed-1b`. See [artifacts/2026-09-08-t2/](artifacts/2026-09-08-t2/).

Tier 3 local OpenCode plus NVIDIA Build ran twice. Both scored 0/4. The first pass hit HTTP 429 and 300s timeouts at concurrency 4. The serialized rerun (`--n-concurrent 1`, `--timeout-multiplier 2`) ran 4458s and still left every dimension `NO SCORE`. The NVIDIA judge timed out. Some OpenCode trials exited 140 or hit the 600s cap. See [artifacts/2026-09-08-t3/](artifacts/2026-09-08-t3/).

Rerun T2 or T3 with [`docs/eval/run-t2-t3.sh`](../run-t2-t3.sh). [SkillEvaluator](https://docs.nvidia.com/skills/skillevaluator/) 0.2.1 chat and embed defaults are EOL. The script pins live NVIDIA models.

Artifacts: [artifacts/](artifacts/).

## How to verify

Two paths. Inspect the committed artifacts with no key. Rerun the live checks if you have an NVIDIA Build key.

### Inspect the artifacts

1. Open [`artifacts/2026-09-08-t2/mission-map-t2-validate.txt`](artifacts/2026-09-08-t2/mission-map-t2-validate.txt).
2. Confirm the table lists 12 PASS rows and `all 2 tiers passed`.
3. Open [`mission-map/skills/mission-map/evals/evals.json`](../../mission-map/skills/mission-map/evals/evals.json).
4. Confirm four case ids. `mission-map-explicit-replan`, `mission-map-implicit-deadline`, `mission-map-contextual-empty-g`, and `mission-map-neg-lint`.

### Rerun Tier 1 and Tier 2

You need `NVIDIA_API_KEY` and `skillevaluator` 0.2.1 on `PATH`. If `skillevaluator` is missing, install it from the [SkillEvaluator quickstart](https://docs.nvidia.com/skills/skillevaluator/quickstart).

```bash
export NVIDIA_API_KEY
unset OPENAI_API_KEY OPENAI_API_BASE OPENAI_BASE_URL
TIERS=2 ./docs/eval/run-t2-t3.sh
```

The script pins `nvidia/nemotron-3.5-lightning-30b-a3b` and `nvidia/nemotron-3-embed-1b`. Do not rely on the 0.2.1 defaults. Those models are EOL and return HTTP 410.

Success. The script prints `wrote …` and the new `mission-map-t2-validate.txt` shows 12/12 PASS, quality A 100, and Context Deduplication clean.

### Rerun Tier 3

You need the Tier 2 setup, plus `opencode` 1.1.35 and `bwrap`. `/tmp` must be writable. Harbor `copytree_secure` holds a directory fd, then `scandir(fd)`. New names stay invisible on btrfs. The script copies the skill onto tmpfs for that reason.

Do not pass `--agent-model opencode=nvidia/…`. OpenCode adds an `nvidia/` prefix. An explicit `nvidia/foo` becomes `foo` and fails the publisher check.

```bash
TIERS=3 ./docs/eval/run-t2-t3.sh
```

The script writes `se_local_patch.py` into the SkillEvaluator venv. Harbor then drops empty `BASH_ENV=""` resets and strips `--thinking`, which OpenCode 1.1.35 rejects.

Success. `mission-map-t3-doctor.txt` shows Harbor `opencode` pass. The evaluate log has scored with-skill and no-skill rows. `NO SCORE` on every dimension means the run did not finish scoring.

If NVIDIA returns HTTP 429, wait and rerun. Keep `--n-concurrent 1`. The first concurrency-4 pass scored 0/4.

## How (tools → tasks)

Same eval-host stack as skills repo:

```text
Orca orchestration Run + Grok/cursor workers
  → NVIDIA SkillEvaluator 0.2.1 (https://docs.nvidia.com/skills/skillevaluator/) quality-check / validate
  → this doc + improvement list
```

See skills write-up for the full tools→tasks table and Orca Run id.

## Tier1 SKILL.md fixes landed

1. Frontmatter: `version: 0.1.0`, `metadata.author` as `Name <email@host>` (GitHub noreply), `metadata.tags`.
2. Description shortened to 122 characters.
3. Body sections: Purpose, Prerequisites, Instructions, Examples, Limitations, Troubleshooting.
4. Validation: empty \(G\) or empty DAG stops and Asks. Troubleshooting table for `mm-kern`, JSON, overwrite.
5. Gitleaks on PATH: secrets scan PASS.
6. Path-like refs in SKILL.md (`bin/mm-kern`, `C/Rust`) removed so SkillSpector scan is complete (LOW/SAFE). Security scan PASS.

Still open: a publication-complete Tier 3 Skill Lift with scored with-skill versus no-skill rows.

## Owner

Steward · eval-host · paired with skills eval 2026-09-08.
