// Spec: flows/specs/craft-run.md
// Laws: flows/bend/LAWS.bend
// Install: copy into ~/.grok/workflows/ or <repo>/.grok/workflows/
// Launch: /workflow craft-run {"change":"…"}
// Sign-off: return the card. Do not start the next flow.

let meta = #{
    name: "craft-run",
    description: "Spec, code, clean, harden, then a fresh QA card.",
    phases: [
        #{ title: "Spec", detail: "acceptance before code" },
        #{ title: "Code", detail: "tests and the implementation" },
        #{ title: "Clean", detail: "CRAP on touched functions" },
        #{ title: "Harden", detail: "mutation score" },
        #{ title: "QA", detail: "fresh context card" },
    ],
    when_to_use: "a settled change that needs spec, implementation, CRAP, mutation, then a fresh QA card",
};

let report_schema = #{
    "type": "object",
    "required": ["notes"],
    "properties": #{
        "notes": #{ "type": "string" },
        "next": #{ "type": "string" },
    },
};

let card_schema = #{
    "type": "object",
    "required": ["spec", "acceptance", "step", "touched", "crap_max", "mutation", "scout", "next"],
    "properties": #{
        "spec": #{ "type": "string" },
        "acceptance": #{ "type": "string" },
        "step": #{ "type": "string" },
        "touched": #{ "type": "string" },
        "crap_max": #{ "type": "string" },
        "mutation": #{ "type": "string" },
        "scout": #{ "type": "string" },
        "next": #{ "type": "string" },
    },
};

fn handoff(label, result) {
    if result == () || !result.success || result.output == () {
        return label + ": (unavailable)";
    }
    let notes = "";
    if result.output.notes != () { notes = result.output.notes; }
    return label + ": " + notes;
}

let change = if args == () { "" } else { if args.change == () { "" } else { args.change } };
phase("Spec");
let spec = agent("Follow flows/specs/craft-run.md and the craft skill. Write the spec and the acceptance before any implementation. Change: " + change + ". Read only. Return the schema object.", #{
    label: "spec",
    capability_mode: "read-only",
    output_schema: report_schema,
    max_turns: 6,
});

phase("Code");
let code = agent("Follow flows/specs/craft-run.md and the craft skill. Implement the change and its tests. " + handoff("spec", spec) + " Change: " + change + ". Return the schema object.", #{
    label: "code",
    capability_mode: "read-write",
    output_schema: report_schema,
    max_turns: 8,
});

phase("Clean");
let clean = agent("Follow flows/specs/craft-run.md and the craft skill. Run CRAP on functions this change touched. Stay inside those files. " + handoff("spec", spec) + " " + handoff("code", code) + " Return the schema object.", #{
    label: "clean",
    capability_mode: "read-write",
    output_schema: report_schema,
    max_turns: 6,
});

phase("Harden");
let harden = agent("Follow flows/specs/craft-run.md and the craft skill. Run the mutation score on non-Bend code this change touched. " + handoff("clean", clean) + " Return the schema object.", #{
    label: "harden",
    capability_mode: "read-write",
    output_schema: report_schema,
    max_turns: 6,
});

phase("QA");
let qa = agent("Follow flows/specs/craft-run.md and the craft skill as QA in a fresh context. Do not implement. Fill the card. " + handoff("spec", spec) + " " + handoff("code", code) + " " + handoff("clean", clean) + " " + handoff("harden", harden) + " Return the schema object.", #{
    label: "qa",
    capability_mode: "read-only",
    output_schema: card_schema,
    max_turns: 6,
});

let card = #{
    spec: "",
    acceptance: "no",
    step: "qa",
    touched: "",
    crap_max: "",
    mutation: "",
    scout: "",
    next: "QA returned nothing",
    sign_off: "stop",
};
if qa != () && qa.success && qa.output != () {
    card = qa.output;
    card.sign_off = "stop";
}
complete(card);
