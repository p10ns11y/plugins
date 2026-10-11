// Fission → fusion (+ optional roadmap). Real skills only.

let meta = #{
    name: "context-ignite",
    description: "Prune context (fission), synthesize surplus (fusion), optional roadmap",
    phases: [
        #{ title: "Fission", detail: "relevance prune + token budget" },
        #{ title: "Fusion", detail: "synthesis + surplus" },
        #{ title: "Roadmap", detail: "optional stellar backlog update" },
    ],
    when_to_use: "large repo context cost; need surplus not just efficiency",
};

let report_schema = #{
    "type": "object",
    "required": ["done", "notes", "surplus"],
    "properties": #{
        "done": #{ "type": "boolean" },
        "notes": #{ "type": "string" },
        "surplus": #{ "type": "string" },
    },
};

let topic = if args == () { () } else { args.topic };
if topic == () {
    pause("verification", "Pass args.topic — what area to ignite (paths or goal).");
}

let want_roadmap = false;
if args != () && args.roadmap != () {
    want_roadmap = args.roadmap == true || args.roadmap == "true";
}

phase("Fission");
let p = "";
p += "Follow ai-optimization (fission). Topic: " + topic + ". ";
p += "Map hierarchy first; score relevance; stay within strict token budget. ";
p += "Do not dump full files. Report {done, notes, surplus} where surplus may be empty this phase.";
let r0 = agent(p, #{
    label: "fission",
    capability_mode: "read-only",
    output_schema: report_schema,
});
if r0 == () || !r0.success { log("Fission failed"); }

phase("Fusion");
let f = "";
f += "Follow architecture-synthesis. Topic: " + topic + ". ";
f += "Synthesize higher-order abstractions from the pruned context. ";
f += "Mandatory surplus: one concrete future-cheaper improvement. ";
f += "Report {done, notes, surplus}.";
let r1 = agent(f, #{
    label: "fusion",
    capability_mode: "read-write",
    output_schema: report_schema,
});
if r1 == () || !r1.success { log("Fusion failed"); }

let r2 = ();
if want_roadmap {
    phase("Roadmap");
    let rp = "";
    rp += "Follow stellar-spacemap if backlog docs exist. Topic: " + topic + ". ";
    rp += "Update or propose SN-style cards only if evidence supports. ";
    rp += "Report {done, notes, surplus}.";
    r2 = agent(rp, #{
        label: "roadmap",
        capability_mode: "read-write",
        output_schema: report_schema,
    });
    if r2 == () || !r2.success { log("Roadmap phase failed"); }
}

complete(#{
    summary: "Finished context-ignite",
    skill_chain: ["ai-optimization", "architecture-synthesis", "stellar-spacemap"],
    fission: r0,
    fusion: r1,
    roadmap: r2,
});
