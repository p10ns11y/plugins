// Generated draft — Grok Build workflow template.
// Install: copy to .grok/workflows/tmux-cockpit-layout-refactor.rhai (or ~/.grok/workflows/).
// Requires Grok host APIs: agent(), phase(), log(), complete() — not rhai-host.
// Skill chain: tmux-layout-swap → remove-redundant-cd-prefix → alias-reload-conflict-fix → priority-test-manifest

let meta = #{
    name: "tmux-cockpit-layout-refactor",
    description: "End-to-end redesign of verify/test cockpits, alias hygiene, test prioritization, and PR review closure",
    phases: [
        #{ title: "Explore", detail: "Grep/Read layout and launch scripts" },
        #{ title: "Implement", detail: "Write/StrReplace new layout and manifest" },
        #{ title: "Verify", detail: "Shell tests + drift check" },
        #{ title: "Review", detail: "fusion-sage + pr-review-canvas on branch" }
    ],
    when_to_use: "End-to-end redesign of verify/test cockpits, alias hygiene, test prioritization, and PR review closure",
};

phase("Explore");
let r0 = agent(
    "Follow skill 'tmux-layout-swap'. Grep/Read layout and launch scripts. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "tmux-layout-swap",
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
    log("phase failed: tmux-layout-swap");
}


phase("Implement");
let r1 = agent(
    "Follow skill 'remove-redundant-cd-prefix'. Write/StrReplace new layout and manifest. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "remove-redundant-cd-prefix",
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
    log("phase failed: remove-redundant-cd-prefix");
}


phase("Verify");
let r2 = agent(
    "Follow skill 'alias-reload-conflict-fix'. Shell tests + drift check. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "alias-reload-conflict-fix",
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
    log("phase failed: alias-reload-conflict-fix");
}


phase("Review");
let r3 = agent(
    "Follow skill 'priority-test-manifest'. fusion-sage + pr-review-canvas on branch. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "priority-test-manifest",
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
    log("phase failed: priority-test-manifest");
}

complete(#{
    summary: "Finished workflow tmux-cockpit-layout-refactor",
    skill_chain: ["tmux-layout-swap","remove-redundant-cd-prefix","alias-reload-conflict-fix","priority-test-manifest"],
});
