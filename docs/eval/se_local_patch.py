"""Harbor local-mode patches for SkillEvaluator 0.2.1.

SkillEvaluator writes BASH_ENV="" into every Harbor task. Docker treats that
as a clear. Local mode rejects the key and dies on the agent --version probe.

Harbor's OpenCode adapter always appends --thinking. OpenCode 1.1.35 rejects
that flag and prints help.

Harbor's CursorCli.install() runs apt-get and curl. Local mode only needs
cursor-agent --version. CursorCli.run() requires CURSOR_API_KEY in the Harbor
parent. Local mode reads the host login token when that env var is unset.

Loaded via a venv .pth so the Harbor subprocess sees the same patch. The
module lives in site-packages so a sandboxed interpreter can import it.
"""

from __future__ import annotations

import os
import shlex
from pathlib import Path

try:
    import skillevaluator.tier3.commands as commands
    import skillevaluator.tier3.harbor as harbor_pkg
    import skillevaluator.tier3.harbor.local_agents as local_agents
    import skillevaluator.tier3.harbor.local_environment as local_environment
    import skillevaluator.tier3.harbor.local_runtime as local_runtime
    import skillevaluator.tier3.harbor.runtime_preflight as runtime_preflight
    import skillevaluator.tier3.harbor.runner as runner
    from harbor.agents.installed.cursor_cli import CursorCli
    from skillevaluator.tier3.harbor.local_agents import SkillEvaluatorLocalOpenCode
except ImportError:
    pass
else:
    _CURSOR_IMPORT = "se_local_patch:SkillEvaluatorLocalCursorCli"

    class SkillEvaluatorLocalCursorCli(CursorCli):
        """Host cursor-agent. No apt-get install. Login token from the host."""

        async def install(self, environment) -> None:
            await self.exec_as_agent(environment, command="cursor-agent --version")

        def get_version_command(self) -> str | None:
            return "cursor-agent --version"

        def _host_cursor_auth(self) -> Path:
            return Path.home() / ".config" / "cursor" / "auth.json"

        async def run(self, instruction, environment, context) -> None:  # type: ignore[no-untyped-def]
            if not self.model_name or "/" not in self.model_name:
                raise ValueError("Model name must be in the format provider/model_name")
            model = self.model_name.split("/")[-1]
            escaped_instruction = shlex.quote(instruction)
            host_auth = self._host_cursor_auth()
            setup = "mkdir -p ~/.config/cursor; "
            if host_auth.is_file():
                setup += f"cp {shlex.quote(str(host_auth))} ~/.config/cursor/auth.json; "
            env = {}
            if os.environ.get("CURSOR_API_KEY", "").strip():
                env["CURSOR_API_KEY"] = os.environ["CURSOR_API_KEY"]
            await self.exec_as_agent(
                environment,
                command=(
                    setup
                    + 'export PATH="$HOME/.local/bin:$PATH"; '
                    + f"cursor-agent --yolo --print --output-format=stream-json --model={model} -- {escaped_instruction} "
                    + f"2>&1 | tee /logs/agent/{self._OUTPUT_FILENAME}"
                ),
                env=env or None,
            )

        async def exec_as_agent(self, environment, command, env=None, cwd=None, timeout_sec=None):
            if isinstance(command, str):
                command = command.replace("| stdbuf -oL tee", "| tee")
            return await super().exec_as_agent(
                environment,
                command=command,
                env=env,
                cwd=cwd,
                timeout_sec=timeout_sec,
            )

    _orig_filter = local_environment.SkillEvaluatorLocalEnvironment._filter_command_env
    _orig_exec = SkillEvaluatorLocalOpenCode.exec_as_agent
    _orig_validate = runner._validate_agent_provider_credentials
    _orig_command_roots = local_runtime.runtime_command_roots
    _orig_disposition = runtime_preflight.credential_probe_disposition

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

    def _validate_agent_provider_credentials(provider, agents, *args, **kwargs):
        others = [agent for agent in agents if agent != "cursor-cli"]
        if not others:
            return []
        return _orig_validate(provider, others, *args, **kwargs)

    def _credential_probe_disposition(provider, probe):
        model = str(getattr(provider, "model", "") or "")
        if model.startswith("cursor/"):
            return runtime_preflight.CredentialProbeDisposition.DEGRADED
        return _orig_disposition(provider, probe)

    def _runtime_command_roots(agents, *, runtime_root=None):
        roots = list(_orig_command_roots(agents, runtime_root=runtime_root))
        if "cursor-cli" in agents:
            found = local_runtime.find_runtime_command("cursor-cli", runtime_root=runtime_root)
            if found:
                package_dir = Path(found).resolve().parent
                if package_dir.is_dir() and package_dir not in roots:
                    roots.append(package_dir)
            cursor_config = Path.home() / ".config" / "cursor"
            if cursor_config.is_dir() and cursor_config not in roots:
                roots.append(cursor_config)
        return roots

    if "cursor-cli" not in local_runtime.LOCAL_RUNTIME_AGENTS:
        local_runtime.LOCAL_RUNTIME_AGENTS = (*local_runtime.LOCAL_RUNTIME_AGENTS, "cursor-cli")
    local_runtime._AGENT_COMMANDS["cursor-cli"] = ("cursor-agent",)
    local_runtime._AGENT_INSTALL_HINTS["cursor-cli"] = "install cursor-agent and put it on PATH"
    local_environment.LOCAL_RUNTIME_AGENTS = local_runtime.LOCAL_RUNTIME_AGENTS

    harbor_pkg.HARBOR_AGENTS_SUPPORTED = frozenset(harbor_pkg.HARBOR_AGENTS_SUPPORTED | {"cursor-cli"})
    harbor_pkg.HARBOR_AGENTS = harbor_pkg.HARBOR_AGENTS_SUPPORTED | harbor_pkg.HARBOR_AGENTS_EXPERIMENTAL
    harbor_pkg.LOCAL_HARBOR_AGENTS = frozenset(harbor_pkg.LOCAL_HARBOR_AGENTS | {"cursor-cli"})
    harbor_pkg.LOCAL_AGENT_IMPORT_PATHS = {
        **harbor_pkg.LOCAL_AGENT_IMPORT_PATHS,
        "cursor-cli": _CURSOR_IMPORT,
    }
    harbor_pkg.AGENT_ALIASES = {**harbor_pkg.AGENT_ALIASES, "cursor-agent": "cursor-cli"}

    local_agents.LOCAL_AGENT_IMPORT_PATHS = {
        **local_agents.LOCAL_AGENT_IMPORT_PATHS,
        "cursor-cli": _CURSOR_IMPORT,
    }

    commands.HARBOR_AGENTS_SUPPORTED = harbor_pkg.HARBOR_AGENTS_SUPPORTED
    commands.HARBOR_AGENTS = harbor_pkg.HARBOR_AGENTS

    local_environment.SkillEvaluatorLocalEnvironment._filter_command_env = staticmethod(_filter_command_env)
    SkillEvaluatorLocalOpenCode.exec_as_agent = _exec_as_agent
    runner._validate_agent_provider_credentials = _validate_agent_provider_credentials
    local_runtime.runtime_command_roots = _runtime_command_roots
    local_environment.runtime_command_roots = _runtime_command_roots
    runtime_preflight.credential_probe_disposition = _credential_probe_disposition
