// Generated draft — Grok Build workflow template.
// Install: copy to .grok/workflows/verification-cockpit-extension.rhai (or ~/.grok/workflows/).
// Requires Grok host APIs: agent(), phase(), log(), complete() — not rhai-host.
// Skill chain: foundation-first-edit → project-config-after-foundation → fix-snacks-explorer-dotfiles

let meta = #{
    name: "verification-cockpit-extension",
    description: "Foundation-first extension of verification-cockpit skill followed by per-project layout config and Neovim visibility fixes",
    phases: [
        #{ title: "Audit", detail: "Read skill, templates, shellyxz delegation and confirm host/project contract" },
        #{ title: "Foundation", detail: "Edit shellyxz, add cockpit.yaml template, make ab/av/at extensible" },
        #{ title: "Project Config", detail: "Apply arch-machine overrides and nvim command hooks" },
        #{ title: "Stabilize", detail: "Fix explorer dotfile visibility and push both PRs" }
    ],
    when_to_use: "Foundation-first extension of verification-cockpit skill followed by per-project layout config and Neovim visibility fixes",
};

phase("Audit");
let r0 = agent(
    "Follow skill 'foundation-first-edit'. Read skill, templates, shellyxz delegation and confirm host/project contract. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "foundation-first-edit",
        capability_mode: "read-only",
        output_schema: #{
            "type": "object",
            "required": ["done", "notes"],
            "properties": #{
                "done": #{ "type": "boolean" },
                "notes": #{ "type": "string" },
            },
        },
    },
);
if r0 == () || !r0.success {
    log("phase failed: foundation-first-edit");
}


phase("Foundation");
let r1 = agent(
    "Follow skill 'project-config-after-foundation'. Edit shellyxz, add cockpit.yaml template, make ab/av/at extensible. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "project-config-after-foundation",
        capability_mode: "read-write",
        output_schema: #{
            "type": "object",
            "required": ["done", "notes"],
            "properties": #{
                "done": #{ "type": "boolean" },
                "notes": #{ "type": "string" },
            },
        },
    },
);
if r1 == () || !r1.success {
    log("phase failed: project-config-after-foundation");
}


phase("Project Config");
let r2 = agent(
    "Follow skill 'fix-snacks-explorer-dotfiles'. Apply arch-machine overrides and nvim command hooks. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "fix-snacks-explorer-dotfiles",
        capability_mode: "read-write",
        output_schema: #{
            "type": "object",
            "required": ["done", "notes"],
            "properties": #{
                "done": #{ "type": "boolean" },
                "notes": #{ "type": "string" },
            },
        },
    },
);
if r2 == () || !r2.success {
    log("phase failed: fix-snacks-explorer-dotfiles");
}


phase("Stabilize");
let r3 = agent(
    "Follow skill 'Stabilize'. Fix explorer dotfile visibility and push both PRs. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "Stabilize",
        capability_mode: "read-write",
        output_schema: #{
            "type": "object",
            "required": ["done", "notes"],
            "properties": #{
                "done": #{ "type": "boolean" },
                "notes": #{ "type": "string" },
            },
        },
    },
);
if r3 == () || !r3.success {
    log("phase failed: Stabilize");
}

complete(#{
    summary: "Finished workflow verification-cockpit-extension",
    skill_chain: ["foundation-first-edit","project-config-after-foundation","fix-snacks-explorer-dotfiles"],
});
