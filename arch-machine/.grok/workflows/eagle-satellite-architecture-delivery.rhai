// Generated draft — Grok Build workflow template.
// Install: copy to .grok/workflows/eagle-satellite-architecture-delivery.rhai (or ~/.grok/workflows/).
// Requires Grok host APIs: agent(), phase(), log(), complete() — not rhai-host.
// Skill chain: eagle-satellite-elomaxz → threat-first-audit-rewrite

let meta = #{
    name: "eagle-satellite-architecture-delivery",
    description: "end-to-end flow from plan approval through FSM implementation, skill extraction, doc updates and push",
    phases: [
        #{ title: "Plan", detail: "incorporate xstate DAGs and Eagle+Satellites registry" },
        #{ title: "Implement", detail: "rewrite app.rs, add state transitions, satellite jobs" },
        #{ title: "Document", detail: "plain-English mermaid diagrams + new architecture skill" },
        #{ title: "Verify", detail: "dry-run, UI fixes, logical commits, push" }
    ],
    when_to_use: "end-to-end flow from plan approval through FSM implementation, skill extraction, doc updates and push",
};

phase("Plan");
let r0 = agent(
    "Follow skill 'eagle-satellite-elomaxz'. incorporate xstate DAGs and Eagle+Satellites registry. Use read-only tools first when mapping; "
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


phase("Implement");
let r1 = agent(
    "Follow skill 'threat-first-audit-rewrite'. rewrite app.rs, add state transitions, satellite jobs. Use read-only tools first when mapping; "
        + "then apply edits. Report {done: bool, notes: string}.",
    #{
        label: "threat-first-audit-rewrite",
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
    log("phase failed: threat-first-audit-rewrite");
}


phase("Document");
let r2 = agent(
    "Follow skill 'Document'. plain-English mermaid diagrams + new architecture skill. Use read-only tools first when mapping; "
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
if r2 == () || !r2.success {
    log("phase failed: Document");
}


phase("Verify");
let r3 = agent(
    "Follow skill 'Verify'. dry-run, UI fixes, logical commits, push. Use read-only tools first when mapping; "
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
if r3 == () || !r3.success {
    log("phase failed: Verify");
}

complete(#{
    summary: "Finished workflow eagle-satellite-architecture-delivery",
    skill_chain: ["eagle-satellite-elomaxz","threat-first-audit-rewrite"],
});
