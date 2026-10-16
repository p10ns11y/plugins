// Spec: flows/specs/mine-corrections.md
// Laws: flows/bend/LAWS.bend
// Install: copy into ~/.grok/workflows/ or <repo>/.grok/workflows/
// Launch: /workflow mine-corrections {"since":"…","paths":["…"]}
// Sign-off: return proposed rules only. Do not edit files. Do not start the next flow.

let meta = #{
    name: "mine-corrections",
    description: "Mine repeated corrections and return proposed rules only.",
    phases: [
        #{ title: "Mine", detail: "one reader per path" },
        #{ title: "Cluster", detail: "group repeated corrections" },
        #{ title: "Filter", detail: "fresh context, keep a rule that would have prevented a miss" },
    ],
    when_to_use: "repeated corrections on known paths. The card is a proposed-rule list.",
};

let note_schema = #{
    "type": "object",
    "required": ["notes"],
    "properties": #{
        "notes": #{
            "type": "array",
            "items": #{
                "type": "object",
                "required": ["path", "correction"],
                "properties": #{
                    "path": #{ "type": "string" },
                    "correction": #{ "type": "string" },
                },
            },
        },
    },
};

let cluster_schema = #{
    "type": "object",
    "required": ["clusters"],
    "properties": #{
        "clusters": #{
            "type": "array",
            "items": #{
                "type": "object",
                "required": ["label", "count"],
                "properties": #{
                    "label": #{ "type": "string" },
                    "count": #{ "type": "number" },
                },
            },
        },
    },
};

let rule_schema = #{
    "type": "object",
    "required": ["rules"],
    "properties": #{
        "rules": #{
            "type": "array",
            "items": #{
                "type": "object",
                "required": ["rule", "prevented"],
                "properties": #{
                    "rule": #{ "type": "string" },
                    "prevented": #{ "type": "boolean" },
                },
            },
        },
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

let since = if args == () { "" } else { if args.since == () { "" } else { args.since } };
let paths = if args == () { [] } else { if args.paths == () { [] } else { args.paths } };
if paths.len() == 0 {
    phase("Filter");
    agent("Follow flows/specs/mine-corrections.md. Fresh context. No paths were given. Do not edit any file. Return rules as an empty list.", #{
        label: "filter",
        capability_mode: "read-only",
        output_schema: rule_schema,
        max_turns: 2,
    });
    complete(#{ rules: [], sign_off: "stop" });
} else {
    phase("Mine");
    let jobs = [];
    for path in paths {
        let prompt = "Follow flows/specs/mine-corrections.md. Read " + path + ". Since " + since + ", list corrections a person repeated. Do not edit any file. Return the schema object.";
        jobs.push(#{
            prompt: prompt,
            label: path,
            capability_mode: "read-only",
            output_schema: note_schema,
        });
    }
    let mined = outputs(parallel(jobs));

    phase("Cluster");
    let notes = json_encode(mined);
    let clustered = agent("Follow flows/specs/mine-corrections.md. Group these corrections by the repeated miss. Drop one-off notes. Notes: " + notes + ". Do not edit any file. Return the schema object.", #{
        label: "cluster",
        capability_mode: "read-only",
        output_schema: cluster_schema,
        max_turns: 6,
    });

    phase("Filter");
    let cluster_text = "(unavailable)";
    if clustered != () && clustered.success && clustered.output != () {
        cluster_text = json_encode(clustered.output);
    }
    let filtered = agent("Follow flows/specs/mine-corrections.md. Fresh context. Keep a cluster only when a rule written from it would have prevented a real miss. Clusters: " + cluster_text + ". Set prevented true only for those. Do not edit any file. Return the schema object.", #{
        label: "filter",
        capability_mode: "read-only",
        output_schema: rule_schema,
        max_turns: 6,
    });
    let rules = [];
    if filtered != () && filtered.success && filtered.output != () && filtered.output.rules != () {
        for item in filtered.output.rules {
            if item.prevented == true {
                rules.push(item.rule);
            }
        }
    }
    complete(#{ rules: rules, sign_off: "stop" });
}
