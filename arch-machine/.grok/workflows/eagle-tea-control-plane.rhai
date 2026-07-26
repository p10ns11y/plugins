// Generated draft — Grok Build workflow template.
// Install: copy to .grok/workflows/eagle-tea-control-plane.rhai (or ~/.grok/workflows/).
// Requires Grok host APIs: agent(), phase(), log(), complete() — not rhai-host.
// Skill chain: eagle-satellite-elomaxz → next-action-clarity-rule

let meta = #{
    name: "eagle-tea-control-plane",
    description: "Build and document Ratatui control plane using Eagle/TEA, xstate FSMs, satellite jobs, and clear next-action guidance",
    phases: [
        #{ title: "Explore", detail: "memory_search + read_file + grep to locate theme, script, and state handling" },
        #{ title: "Plan", detail: "todo_write + enter_plan_mode incorporating xstate DAGs" },
        #{ title: "Implement", detail: "search_replace + write for app.rs, FSM, and Grok preload" },
        #{ title: "Document", detail: "write docs with mermaid diagrams and create architecture skill" },
        #{ title: "Verify", detail: "run_terminal_command + update_goal for UI fixes and PR" }
    ],
    when_to_use: "Build and document Ratatui control plane using Eagle/TEA, xstate FSMs, satellite jobs, and clear next-action guidance",
};

phase("Explore");
let r0 = agent(
    "Follow skill 'eagle-satellite-elomaxz'. memory_search + read_file + grep to locate theme, script, and state handling. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "eagle-satellite-elomaxz",
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
    log("phase failed: eagle-satellite-elomaxz");
}


phase("Plan");
let r1 = agent(
    "Follow skill 'next-action-clarity-rule'. todo_write + enter_plan_mode incorporating xstate DAGs. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "next-action-clarity-rule",
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
    log("phase failed: next-action-clarity-rule");
}


phase("Implement");
let r2 = agent(
    "Follow skill 'Implement'. search_replace + write for app.rs, FSM, and Grok preload. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "Implement",
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
    log("phase failed: Implement");
}


phase("Document");
let r3 = agent(
    "Follow skill 'Document'. write docs with mermaid diagrams and create architecture skill. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "Document",
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
    log("phase failed: Document");
}


phase("Verify");
let r4 = agent(
    "Follow skill 'Verify'. run_terminal_command + update_goal for UI fixes and PR. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "Verify",
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
if r4 == () || !r4.success {
    log("phase failed: Verify");
}

complete(#{
    summary: "Finished workflow eagle-tea-control-plane",
    skill_chain: ["eagle-satellite-elomaxz","next-action-clarity-rule"],
});
