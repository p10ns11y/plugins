// Spec: flows/specs/rule-review.md
// Laws: flows/bend/LAWS.bend
// Install: copy into ~/.grok/workflows/ or <repo>/.grok/workflows/
// Launch: /workflow rule-review {"diff":"…","rulesFile":"…"}
// Sign-off: return the flag card. Do not merge and do not start the next flow.

let meta = #{
    name: "rule-review",
    description: "One verifier per rule, then a skeptic. Returns flags with evidence lines.",
    phases: [
        #{ title: "Split", detail: "read the rules file" },
        #{ title: "Verify", detail: "one SI per rule" },
        #{ title: "Skeptic", detail: "fresh context before the flag card" },
    ],
    when_to_use: "one diff and one rules file. The flow returns flags. It does not land.",
};

let rules_schema = #{
    "type": "object",
    "required": ["rules"],
    "properties": #{
        "rules": #{
            "type": "array",
            "items": #{
                "type": "object",
                "required": ["id", "text"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "text": #{ "type": "string" },
                },
            },
        },
    },
};

let hit_schema = #{
    "type": "object",
    "required": ["hit", "ruleId", "evidence"],
    "properties": #{
        "hit": #{ "type": "boolean" },
        "ruleId": #{ "type": "string" },
        "evidence": #{ "type": "string" },
    },
};

let verdict_schema = #{
    "type": "object",
    "required": ["keep", "ruleId", "evidence"],
    "properties": #{
        "keep": #{ "type": "boolean" },
        "ruleId": #{ "type": "string" },
        "evidence": #{ "type": "string" },
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

let diff = if args == () { () } else { args.diff };
let rules_file = if args == () { () } else { args.rulesFile };
if diff == () || diff == "" || rules_file == () || rules_file == "" {
    phase("Skeptic");
    agent("Follow flows/specs/rule-review.md. Fresh context. The diff or the rules file is missing. Return keep false, ruleId none, and evidence none.", #{
        label: "skeptic",
        capability_mode: "read-only",
        output_schema: verdict_schema,
        max_turns: 2,
    });
    complete(#{ flags: [], sign_off: "stop" });
} else {
    phase("Split");
    let split = agent("Follow flows/specs/rule-review.md. Read " + rules_file + ". List each hard rule as id and text. Do not review the diff yet. Return the schema object.", #{
        label: "split",
        capability_mode: "read-only",
        output_schema: rules_schema,
        max_turns: 4,
    });
    let rules = [];
    if split != () && split.success && split.output != () && split.output.rules != () {
        rules = split.output.rules;
    }

    phase("Verify");
    let hits = [];
    if rules.len() > 0 {
        let jobs = [];
        for rule in rules {
            let prompt = "Follow flows/specs/rule-review.md. Diff:\n" + diff + "\nRule " + rule.id + ": " + rule.text + "\nSet hit true only when a diff line breaks the rule. evidence is that line. Return the schema object.";
            jobs.push(#{
                prompt: prompt,
                label: rule.id,
                capability_mode: "read-only",
                output_schema: hit_schema,
            });
        }
        hits = outputs(parallel(jobs));
    }
    let flagged = [];
    for hit in hits {
        if hit.hit == true {
            flagged.push(hit);
        }
    }

    phase("Skeptic");
    let verdicts = [];
    if flagged.len() == 0 {
        let alone = agent("Follow flows/specs/rule-review.md. Fresh context. There are no flags. Return keep false, ruleId none, and evidence none.", #{
            label: "skeptic",
            capability_mode: "read-only",
            output_schema: verdict_schema,
            max_turns: 2,
        });
        verdicts = outputs([alone]);
    } else {
        let jobs = [];
        for flag in flagged {
            let prompt = "Follow flows/specs/rule-review.md. Fresh context. Try to refute this flag. Diff:\n" + diff + "\nRule " + flag.ruleId + ". Evidence: " + flag.evidence + "\nSet keep true when that evidence line is in the diff and the rule covers it. Do not drop a flag only because the wording is sharp. Return the schema object.";
            jobs.push(#{
                prompt: prompt,
                label: flag.ruleId,
                capability_mode: "read-only",
                output_schema: verdict_schema,
            });
        }
        verdicts = outputs(parallel(jobs));
    }
    let flags = [];
    for verdict in verdicts {
        if verdict.keep == true {
            flags.push(#{ ruleId: verdict.ruleId, evidence: verdict.evidence });
        }
    }
    complete(#{ flags: flags, sign_off: "stop" });
}
