// Spec: flows/specs/eva.md
// Laws: flows/bend/LAWS.bend
// Install: copy into ~/.grok/workflows/ or <repo>/.grok/workflows/
// Launch: /workflow eva {"goal":"…"}
// This file is the Claude eva port. eva-emptiness.rhai stays the longer Prior → ActOrAsk flow.
// Sign-off: return the survivor card or an ask card. Do not start the next flow.

let meta = #{
    name: "eva",
    description: "Prior-diverse hypotheses, then refuters, for at most three rounds.",
    phases: [
        #{ title: "Prior", detail: "conservative, generative, and causal" },
        #{ title: "Refute", detail: "one refuter per live hypothesis" },
    ],
    when_to_use: "a goal with competing hypotheses. At most three refute rounds, then a card.",
};

let hyp_schema = #{
    "type": "object",
    "required": ["id", "kind", "claim"],
    "properties": #{
        "id": #{ "type": "string" },
        "kind": #{ "type": "string" },
        "claim": #{ "type": "string" },
        "evidence": #{ "type": "string" },
    },
};

let ref_schema = #{
    "type": "object",
    "required": ["id", "refuted"],
    "properties": #{
        "id": #{ "type": "string" },
        "refuted": #{ "type": "boolean" },
        "because": #{ "type": "string" },
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

let goal = if args == () { () } else { args.goal };
if goal == () || goal == "" {
    phase("Refute");
    agent("Follow flows/specs/eva.md. Fresh context. No goal was given. Read only. Return id none and refuted true.", #{
        label: "refute",
        capability_mode: "read-only",
        output_schema: ref_schema,
        max_turns: 2,
    });
    complete(#{ survivor: (), rounds: 0, ask: true, standing: [], sign_off: "stop" });
} else {
    phase("Prior");
    let jobs = [];
    for kind in ["conservative", "generative", "causal"] {
        let prompt = "Follow flows/specs/eva.md and eva-emptiness. Goal: " + goal + ". Take the " + kind + " prior and state one hypothesis. Set id to " + kind + ". Read only. Return the schema object.";
        jobs.push(#{
            prompt: prompt,
            label: kind,
            capability_mode: "read-only",
            output_schema: hyp_schema,
        });
    }
    let live = outputs(parallel(jobs));
    let round = 0;
    let stop = false;
    for n in [0, 1, 2] {
        if !stop && live.len() > 0 {
            phase("Refute");
            let refute_jobs = [];
            for hyp in live {
                let prompt = "Follow flows/specs/eva.md. Fresh context. Try to refute this hypothesis for the goal: " + goal + ". Hypothesis id " + hyp.id + " kind " + hyp.kind + " claim " + hyp.claim + ". Echo id " + hyp.id + ". Set refuted true when the claim does not hold. Read only. Return the schema object.";
                refute_jobs.push(#{
                    prompt: prompt,
                    label: hyp.id,
                    capability_mode: "read-only",
                    output_schema: ref_schema,
                });
            }
            let votes = outputs(parallel(refute_jobs));
            let kept = [];
            for hyp in live {
                let stay = false;
                for vote in votes {
                    if vote.id == hyp.id && vote.refuted == false {
                        stay = true;
                    }
                }
                if stay { kept.push(hyp); }
            }
            live = kept;
            round += 1;
            if live.len() <= 1 {
                stop = true;
            }
        }
    }
    if round == 0 {
        phase("Refute");
        agent("Follow flows/specs/eva.md. Fresh context. No hypothesis is live. Read only. Return id none and refuted true.", #{
            label: "refute",
            capability_mode: "read-only",
            output_schema: ref_schema,
            max_turns: 2,
        });
    }
    let survivor = ();
    let ask = true;
    if live.len() == 1 {
        survivor = live[0];
        ask = false;
    }
    complete(#{ survivor: survivor, rounds: round, ask: ask, standing: live, sign_off: "stop" });
}
