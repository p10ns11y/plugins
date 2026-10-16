// Spec: flows/specs/capture-sweep.md
// Install: copy into ~/.grok/workflows/ or <repo>/.grok/workflows/
// Launch: /workflow capture-sweep
// Sign-off: return the card. Do not post, pay, or sign. Do not start the next flow.

let meta = #{
    name: "capture-sweep",
    description: "Read-only capture, a fresh verifier, then one actor writes tstack-state.",
    phases: [
        #{ title: "Read", detail: "mail, calendar, chat, and pull requests" },
        #{ title: "Verify", detail: "fresh context before the card" },
        #{ title: "Act", detail: "the only writer of tstack-state" },
    ],
    when_to_use: "sweep capture sources. Readers stay read-only. Only the last step writes tstack-state.",
};

let card_schema = #{
    "type": "object",
    "required": ["source", "cards"],
    "properties": #{
        "source": #{ "type": "string" },
        "cards": #{
            "type": "array",
            "items": #{
                "type": "object",
                "required": ["title", "kind"],
                "properties": #{
                    "title": #{ "type": "string" },
                    "kind": #{ "type": "string" },
                },
            },
        },
    },
};

let verdict_schema = #{
    "type": "object",
    "required": ["ok"],
    "properties": #{
        "ok": #{ "type": "boolean" },
        "because": #{ "type": "string" },
    },
};

let act_schema = #{
    "type": "object",
    "required": ["stored", "held"],
    "properties": #{
        "stored": #{ "type": "number" },
        "held": #{ "type": "number" },
    },
};

fn outputs(results) {
    let out = [];
    if results == () { return out; }
    for r in results {
        if r != () && r.success && r.output != () {
            out.push(r.output);
        }
    }
    return out;
}

let sources = [
    #{ id: "mail", skill: "capture-mail" },
    #{ id: "calendar", skill: "capture-calendar" },
    #{ id: "chat", skill: "capture-chat" },
    #{ id: "pr", skill: "capture-pr" },
];

phase("Read");
let jobs = [];
for source in sources {
    let prompt = "Follow flows/specs/capture-sweep.md and " + source.skill + ". Source id " + source.id + ". Read only and return summary cards. Kind is none, money, post, or sign. Return the schema object.";
    jobs.push(#{
        prompt: prompt,
        label: source.id,
        capability_mode: "read-only",
        output_schema: card_schema,
    });
}
let reads = outputs(parallel(jobs));

phase("Verify");
let packed = json_encode(reads);
let verdict = agent("Follow flows/specs/capture-sweep.md. Fresh context. Check these cards. Read only. Set ok true when every card has a source and a kind. Do not write. Cards: " + packed + ". Return the schema object.", #{
    label: "verify",
    capability_mode: "read-only",
    output_schema: verdict_schema,
    max_turns: 4,
});

phase("Act");
let verdict_text = "(unavailable)";
if verdict != () && verdict.success && verdict.output != () {
    verdict_text = json_encode(verdict.output);
}
let acted = agent("Follow flows/specs/capture-sweep.md. You are the only writer. Store kind none through tstack-state. Hold kind money, post, or sign for a person. Do not post, pay, or sign. Verdict: " + verdict_text + ". Cards: " + packed + ". Return the schema object.", #{
    label: "act",
    capability_mode: "read-write",
    output_schema: act_schema,
    max_turns: 6,
});
let stored = 0;
let held = 0;
let ok = false;
if verdict != () && verdict.success && verdict.output != () && verdict.output.ok == true {
    ok = true;
}
if acted != () && acted.success && acted.output != () {
    if acted.output.stored != () { stored = acted.output.stored; }
    if acted.output.held != () { held = acted.output.held; }
}
complete(#{ cards: reads, ok: ok, stored: stored, held: held, sign_off: "stop" });
