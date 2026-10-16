# Workflows

```text
workflows/*.js
  export const meta     first statement, literals only
        |
        v
/<plugin>:<meta.name>
  phase -> agent | pipeline | parallel, then .filter(Boolean)
        |
        v
  return a card for a person
```

Claude Code reads `workflows/*.js` from the plugin folder. A plugin does not need its own `.claude-plugin/plugin.json` for that scan. Grok still uses `.grok/workflows/*.rhai`, copied into a workflows root.

```text
flows/specs/*.md
        |
        +-- workflows/*.js
        +-- .grok/workflows/*.rhai
        +-- flows/portable/*.md
```

Five flows share one spec each. The three variants name that spec.

`schema` when the result feeds a decision. `model` names a verifier tier, such as `opus`. `isolation: 'worktree'` is only for parallel writers. Pass time in `args`. No `Date.now`, `Math.random`, `new Date()`, or `import()`. The script does not land a branch. Hook commands name both `${CLAUDE_PLUGIN_ROOT}` and `${GROK_PLUGIN_ROOT}`.
