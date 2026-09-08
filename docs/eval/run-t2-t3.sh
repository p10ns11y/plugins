#!/usr/bin/env bash
# Rerun SkillEvaluator Tiers 2 and 3 for mission-map with NVIDIA Build.
# SkillEvaluator 0.2.1 defaults (nemotron-3-nano-30b-a3b, nv-embed-v1) are EOL.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
skill="$root/mission-map/skills/mission-map"
stamp="${EVAL_STAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
out="${EVAL_OUT:-$root/docs/eval/2026-09-08/artifacts/$stamp}"
results="${SKILLEVALUATOR_RESULTS_DIR:-$root/docs/eval/2026-09-08/results}"
tiers="${TIERS:-2}"

mkdir -p "$out" "$results"

if [ -z "${NVIDIA_API_KEY:-}" ]; then
	printf 'NVIDIA_API_KEY is unset\n' >&2
	exit 1
fi

export SKILL_EVAL_LLM_PROVIDER=nv_build
export SKILL_EVAL_LLM_MODEL="${SKILL_EVAL_LLM_MODEL:-nvidia/nemotron-3.5-lightning-30b-a3b}"
export SKILL_EVAL_EMBEDDING_PROVIDER=nv_build
export SKILL_EVAL_EMBEDDING_MODEL="${SKILL_EVAL_EMBEDDING_MODEL:-nvidia/nemotron-3-embed-1b}"
export SKILLEVALUATOR_RESULTS_DIR="$results"
# Harbor's secure copy holds a directory fd, writes files, then scandir(fd).
# btrfs does not show those new names on the held fd. tmpfs does.
export TMPDIR="${SKILLEVALUATOR_TMPDIR:-/tmp}"
unset OPENAI_API_KEY OPENAI_API_BASE OPENAI_BASE_URL

se_py="$(sed -n '1s/^#!//p' "$(command -v skillevaluator)")"
se_site="$("$se_py" -c 'import pathlib, skillevaluator; print(pathlib.Path(skillevaluator.__file__).resolve().parents[1])')"
# Copy the patch into site-packages. A path-line .pth cannot be imported
# inside Harbor's bwrap sandbox, which cannot see the repo.
cp -f "$root/docs/eval/se_local_patch.py" "$se_site/se_local_patch.py"
printf '%s\n' "import se_local_patch" >"$se_site/se-local-patch.pth"
se_eval() {
	"$se_py" "$root/docs/eval/se-local-cli.py" "$@"
}

run_t2() {
	skillevaluator validate "$skill" \
		--tiers 1,2 \
		-c \
		-r cli,json,markdown \
		-o "$out" \
		| tee "$out/mission-map-t2-validate.txt"
}

run_t3() {
	if [ ! -f "$skill/evals/evals.json" ]; then
		skillevaluator create-eval-dataset "$skill" --full \
			| tee "$out/mission-map-t3-dataset.txt"
	fi
	# OpenCode prefixes nv_build models with nvidia/. An explicit
	# --agent-model nvidia/foo is stripped to foo and rejected.
	stage="$(mktemp -d "${TMPDIR%/}/mission-map-t3.XXXXXX")"
	trap 'rm -rf "$stage"' EXIT
	cp -a "$skill/." "$stage/"
	# cursor-cli is Harbor's name for cursor-agent. OpenCode plus NVIDIA
	# for both agent and judge 429'd. Split them: Cursor agent, NVIDIA judge.
	# Do not pass --verify-models. cursor/composer-2.5 is not an NVIDIA id.
	se_eval doctor --env-mode local --agents cursor-cli \
		--agent-model cursor-cli=cursor/composer-2.5 \
		| tee "$out/mission-map-t3-doctor.txt"
	se_eval tier3 evaluate "$stage" \
		--env-mode local \
		--agents cursor-cli \
		--agent-model cursor-cli=cursor/composer-2.5 \
		--n-concurrent 1 \
		--timeout-multiplier 2 \
		--results-dir "$results" \
		| tee "$out/mission-map-t3-evaluate.txt"
}

case "$tiers" in
	2) run_t2 ;;
	3) run_t3 ;;
	2,3|23|all)
		run_t2
		run_t3
		;;
	*)
		printf 'TIERS must be 2, 3, or 2,3\n' >&2
		exit 1
		;;
esac

printf 'wrote %s\n' "$out"
