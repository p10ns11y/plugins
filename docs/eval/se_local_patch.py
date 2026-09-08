"""Harbor local-mode patches for SkillEvaluator 0.2.1.

SkillEvaluator writes BASH_ENV="" into every Harbor task. Docker treats that
as a clear. Local mode rejects the key and dies on the agent --version probe.

Harbor's OpenCode adapter always appends --thinking. OpenCode 1.1.35 rejects
that flag and prints help. Local OpenCode already strips
--dangerously-skip-permissions for the same reason.

Loaded via a venv .pth so the Harbor subprocess sees the same patch. The
module lives in site-packages so a sandboxed interpreter can import it.
"""

from __future__ import annotations

try:
    import skillevaluator.tier3.harbor.local_environment as local_environment
    from skillevaluator.tier3.harbor.local_agents import SkillEvaluatorLocalOpenCode
except ImportError:
    pass
else:
    _orig_filter = local_environment.SkillEvaluatorLocalEnvironment._filter_command_env
    _orig_exec = SkillEvaluatorLocalOpenCode.exec_as_agent

    def _filter_command_env(env: dict[str, str], *, protected: set[str]) -> dict[str, str]:
        cleaned = {}
        for key, value in env.items():
            normalized = key.upper()
            blocked = normalized in local_environment._BLOCKED_COMMAND_ENV_NAMES or normalized.startswith(
                local_environment._BLOCKED_COMMAND_ENV_PREFIXES
            )
            if blocked and value == "":
                continue
            cleaned[key] = value
        return _orig_filter(cleaned, protected=protected)

    async def _exec_as_agent(self, environment, command, env=None, cwd=None, timeout_sec=None):
        if isinstance(command, str):
            command = command.replace(" --thinking", "", 1)
        return await _orig_exec(self, environment, command, env=env, cwd=cwd, timeout_sec=timeout_sec)

    local_environment.SkillEvaluatorLocalEnvironment._filter_command_env = staticmethod(_filter_command_env)
    SkillEvaluatorLocalOpenCode.exec_as_agent = _exec_as_agent
