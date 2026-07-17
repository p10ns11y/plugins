# plugins

Grok Build / agent plugins (installable skill + command packages).

## premflow

Capture notes, wins, tasks; review; **coach** from real ledger data; interactive
pomo in an external TTY; journal without hanging the agent.

**CLI repo:** [https://github.com/thecuriousts/premflow](https://github.com/thecuriousts/premflow)

```bash
# install plugin
grok plugin install ./premflow --trust
# or: ln -sfn "$(pwd)/premflow" ~/.grok/plugins/premflow

# install CLI (on PATH) — or use /init inside Grok after plugin install
git clone https://github.com/thecuriousts/premflow.git
cd premflow && ./build.sh && make install   # → ~/.local/bin
```

Slash commands: `/init` `/note` `/win` `/task` `/review` `/coach` `/focus` `/journal`.

See [premflow/README.md](premflow/README.md).
