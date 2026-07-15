# plugins

Personal Grok Build / agent plugins (installable skill + command packages).

## premflow

Capture notes, wins, tasks; review; **coach** from real ledger data; interactive
pomo in an external TTY; journal without hanging the agent.

```bash
# discover
ln -sfn ~/Work/personal/plugins/premflow ~/.grok/plugins/premflow
ln -sfn ~/Work/personal/plugins/premflow/skills/premflow ~/.grok/skills/premflow

# or
grok plugin install ~/Work/personal/plugins/premflow --trust
```

Requires [premflow](https://github.com/thecuriousts/premflow) CLI on PATH (or
`~/Work/personal/premflow/build/premflow`).

Slash commands: `/note` `/win` `/task` `/review` `/coach` `/focus` `/journal`.

See [premflow/README.md](premflow/README.md).
