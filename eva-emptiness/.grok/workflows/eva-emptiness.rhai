// EVA emptiness — host-owned background workflow (Rhai).
// Install (required — plugins do NOT auto-register .rhai):
//   cp .grok/workflows/eva-emptiness.rhai ~/.grok/workflows/
//   # or: <repo>/.grok/workflows/
// Launch: /workflow eva-emptiness {"goal":"…"}
// Interactive alternative: /eva (plugin command) — human stays in plan/ask loop.
// Skills: eva-emptiness (+ control-graph Outer if multi-step delivery follows)

let meta = #{
    name: "eva-emptiness",
    description: "Prior → Probe → Simulate → Score → ActOrAsk under epistemic emptiness",
    phases: [
        #{ title: "Prior", detail: "emptiness gate, knowns/unknowns, honest IDK" },
        #{ title: "Probe", detail: "one DOE question + explore probes" },
        #{ title: "Simulate", detail: "prior-diverse forks → bias_map" },
        #{ title: "Score", detail: "blind review ⊥ implementer" },
        #{ title: "ActOrAsk", detail: "critical-path Act or HITL Ask" },
    ],
    when_to_use: "blank sheet / unknowns dominate / auth unclear — not obvious one-path fixes",
};

let report_schema = #{
    "type": "object",
    "required": ["done", "phase", "notes", "evidence_gain", "next"],
    "properties": #{
        "done": #{ "type": "boolean" },
        "phase": #{ "type": "string" },
        "notes": #{ "type": "string" },
        "evidence_gain": #{ "type": "array", "items": #{ "type": "string" } },
        "next": #{ "type": "string" },
    },
};

let goal = if args == () { () } else { args.goal };
if goal == () {
    pause("verification", "Pass args.goal — one-sentence blank-sheet outcome.");
}

phase("Prior");
let prior_prompt = "";
prior_prompt += "Follow skill eva-emptiness (E0). Goal: " + goal + ". ";
prior_prompt += "Open Control Card fields: emptiness_score, knowns[], unknowns[], idk (≥1), probe_budget=3. ";
prior_prompt += "If emptiness_score=low and path is clear, set next=skip_eva and stop expanding. ";
prior_prompt += "Read-only tools only. Never --always-approve. ";
prior_prompt += "Report {done, phase, notes, evidence_gain, next}.";
let r0 = agent(prior_prompt, #{
    label: "eva-prior",
    capability_mode: "read-only",
    output_schema: report_schema,
});
if r0 == () || !r0.success {
    log("phase failed: Prior");
    complete(#{ summary: "Prior failed", ok: false });
}

phase("Probe");
let probe_prompt = "";
probe_prompt += "Follow skill eva-emptiness (E1–E2). Goal: " + goal + ". ";
probe_prompt += "Ask/record ONE DOE question that most reduces ignorance, then run explore-style probes. ";
probe_prompt += "Append evidence_gain only for new confirm/falsify. Stay in ask/plan discipline. ";
probe_prompt += "Report {done, phase, notes, evidence_gain, next}.";
let r1 = agent(probe_prompt, #{
    label: "eva-probe",
    capability_mode: "read-only",
    output_schema: report_schema,
});
if r1 == () || !r1.success {
    log("phase failed: Probe");
}

phase("Simulate");
let sim_prompt = "";
sim_prompt += "Follow skill eva-emptiness (E3). Goal: " + goal + ". ";
sim_prompt += "Run three prior-diverse forks (prefer plugin agents if installed): ";
sim_prompt += "prior-conservative, prior-generative, prior-causal. ";
sim_prompt += "Prefer worktree isolation for any edits. Build bias_map from disagreements. ";
sim_prompt += "Report {done, phase, notes, evidence_gain, next}.";
let r2 = agent(sim_prompt, #{
    label: "eva-simulate",
    capability_mode: "read-write",
    output_schema: report_schema,
});
if r2 == () || !r2.success {
    log("phase failed: Simulate");
}

phase("Score");
let score_prompt = "";
score_prompt += "Follow skill eva-emptiness (E4) as REVIEW role — fresh context. Goal: " + goal + ". ";
score_prompt += "Score from plan + diffs + probe notes only (⊥ implementer transcript). ";
score_prompt += "Axes: evidence_gain, robustness_under_forks, trauma_flags, critical_path_claim. ";
score_prompt += "Report {done, phase, notes, evidence_gain, next} where next is Act or Ask.";
let r3 = agent(score_prompt, #{
    label: "eva-score",
    capability_mode: "execute",
    output_schema: report_schema,
});
if r3 == () || !r3.success {
    log("phase failed: Score");
}

phase("ActOrAsk");
let act_prompt = "";
act_prompt += "Follow skill eva-emptiness (E5–E6) + control-graph Outer if delivery continues. Goal: " + goal + ". ";
act_prompt += "If Score next=Ask or auth_horizon=hit: produce structured HITL preview only (approve/amend/abort). Do not mutate. ";
act_prompt += "If Act: only Claim-via-critical-path steps; no yolo; run verify cmds; hand off to multi-agent-delivery workflow if multi-worker needed. ";
act_prompt += "Report {done, phase, notes, evidence_gain, next}.";
let r4 = agent(act_prompt, #{
    label: "eva-actorask",
    capability_mode: "read-write",
    output_schema: report_schema,
});
if r4 == () || !r4.success {
    log("phase failed: ActOrAsk");
}

complete(#{
    summary: "Finished eva-emptiness workflow",
    skill_chain: ["eva-emptiness", "control-graph"],
    suggest_next_workflows: ["multi-agent-delivery", "context-ignite"],
    prior: r0,
    probe: r1,
    simulate: r2,
    score: r3,
    actorask: r4,
});
