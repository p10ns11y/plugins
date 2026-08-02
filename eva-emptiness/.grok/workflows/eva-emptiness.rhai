// EVA emptiness — host-owned background workflow (Rhai).
// Install (required — plugins do NOT auto-register .rhai):
//   cp .grok/workflows/eva-emptiness.rhai ~/.grok/workflows/
//   # or: <repo>/.grok/workflows/
// Launch: /workflow eva-emptiness {"goal":"…"}
// Interactive alternative: /eva (plugin command) — human stays in plan/ask loop.
// Skills: eva-emptiness (+ control-graph Outer if multi-step delivery follows)
// Handoff: each phase receives compact prior output (not goal-only re-prompt).

let meta = #{
    name: "eva-emptiness",
    description: "Prior → Probe → Simulate → Score → ActOrAsk under epistemic emptiness",
    phases: [
        #{ title: "Prior", detail: "emptiness gate, knowns/unknowns, honest IDK" },
        #{ title: "Probe", detail: "one DOE question + explore probes" },
        #{ title: "Simulate", detail: "prior-diverse pathways → bias_map + signposts" },
        #{ title: "Score", detail: "blind review ⊥ implementer; robust + option-preserve" },
        #{ title: "ActOrAsk", detail: "continue | switch | Ask" },
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
        "pathway_id": #{ "type": "string" },
        "signposts": #{ "type": "array", "items": #{ "type": "string" } },
        "kill_experiment": #{ "type": "string" },
    },
};

// Compact prior-phase output for the next prompt (no transcripts).
fn compact_handoff(label, result) {
    if result == () || !result.success || result.output == () {
        return label + ": (unavailable)";
    }
    let out = result.output;
    let line = label + ":";
    if out.next != () { line += " next=" + out.next + ";"; }
    if out.pathway_id != () { line += " pathway_id=" + out.pathway_id + ";"; }
    if out.kill_experiment != () { line += " kill_experiment=" + out.kill_experiment + ";"; }
    if out.notes != () { line += " notes=" + out.notes + ";"; }
    if out.evidence_gain != () { line += " evidence_gain=" + out.evidence_gain + ";"; }
    if out.signposts != () { line += " signposts=" + out.signposts + ";"; }
    return line;
}

let goal = if args == () { () } else { args.goal };
if goal == () {
    pause("verification", "Pass args.goal — one-sentence blank-sheet outcome.");
}

phase("Prior");
let prior_prompt = "";
prior_prompt += "Follow skill eva-emptiness (E0). Goal: " + goal + ". ";
prior_prompt += "Open Control Card fields: emptiness_score, knowns[], unknowns[], idk (≥1), probe_budget=3, kill_experiment. ";
prior_prompt += "If emptiness_score=low and path is clear, set next=skip_eva and stop expanding. ";
prior_prompt += "Read-only tools only. Never --always-approve. ";
prior_prompt += "Report {done, phase, notes, evidence_gain, next, kill_experiment}.";
let r0 = agent(prior_prompt, #{
    label: "eva-prior",
    capability_mode: "read-only",
    output_schema: report_schema,
    max_turns: 8,
});
if r0 == () || !r0.success {
    log("phase failed: Prior");
    complete(#{ summary: "Prior failed", ok: false });
}
if r0.output != () && r0.output.next == "skip_eva" {
    complete(#{
        summary: "EVA skipped — emptiness_score low / path clear",
        ok: true,
        prior: r0,
    });
}

phase("Probe");
let probe_prompt = "";
probe_prompt += "Follow skill eva-emptiness (E1–E2). Goal: " + goal + ". ";
probe_prompt += "Prior handoff (compact): " + compact_handoff("prior", r0) + " ";
probe_prompt += "Ask/record ONE DOE question that most reduces ignorance, then run explore-style probes. ";
probe_prompt += "Append evidence_gain only for new confirm/falsify. Stay in ask/plan discipline. ";
probe_prompt += "Report {done, phase, notes, evidence_gain, next}.";
let r1 = agent(probe_prompt, #{
    label: "eva-probe",
    capability_mode: "read-only",
    output_schema: report_schema,
    max_turns: 6,
});
if r1 == () || !r1.success {
    log("phase failed: Probe");
}

phase("Simulate");
let sim_prompt = "";
sim_prompt += "Follow skill eva-emptiness (E3). Goal: " + goal + ". ";
sim_prompt += "Prior handoff: " + compact_handoff("prior", r0) + " ";
sim_prompt += "Probe handoff: " + compact_handoff("probe", r1) + " ";
sim_prompt += "Run three prior-diverse pathway forks (prefer plugin agents if installed): ";
sim_prompt += "prior-conservative, prior-generative, prior-causal. ";
sim_prompt += "Each pathway: short-term action, tipping/failure condition, signposts that force switch. ";
sim_prompt += "Prefer worktree isolation for any edits. Build bias_map from disagreements. ";
sim_prompt += "Report {done, phase, notes, evidence_gain, next, pathway_id, signposts}.";
let r2 = agent(sim_prompt, #{
    label: "eva-simulate",
    capability_mode: "read-write",
    output_schema: report_schema,
    max_turns: 8,
});
if r2 == () || !r2.success {
    log("phase failed: Simulate");
}

phase("Score");
let score_prompt = "";
score_prompt += "Follow skill eva-emptiness (E4) as REVIEW role — fresh context. Goal: " + goal + ". ";
score_prompt += "Handoffs only (⊥ implementer transcript): ";
score_prompt += compact_handoff("prior", r0) + " | ";
score_prompt += compact_handoff("probe", r1) + " | ";
score_prompt += compact_handoff("simulate", r2) + " ";
score_prompt += "Axes: evidence_gain, robustness_under_forks, robust_satisficing, option_preserve, trauma_flags, critical_path_claim. ";
score_prompt += "Report {done, phase, notes, evidence_gain, next, pathway_id} where next is continue, switch, or Ask.";
let r3 = agent(score_prompt, #{
    label: "eva-score",
    capability_mode: "execute",
    output_schema: report_schema,
    max_turns: 8,
});
if r3 == () || !r3.success {
    log("phase failed: Score");
}

phase("ActOrAsk");
let act_prompt = "";
act_prompt += "Follow skill eva-emptiness (E5–E6) + control-graph Outer if delivery continues. Goal: " + goal + ". ";
act_prompt += "Score handoff: " + compact_handoff("score", r3) + " ";
act_prompt += "Simulate handoff: " + compact_handoff("simulate", r2) + " ";
act_prompt += "If Score next=Ask or auth_horizon=hit: produce structured HITL preview only (approve/amend/abort). Do not mutate. ";
act_prompt += "If next=switch: set pathway_active; re-ORIENT via control-graph — do not silent-Act; structured preview if human ack needed. ";
act_prompt += "If next=continue (or Act): only Claim-via-critical-path steps; no yolo; run verify cmds; hand off to multi-agent-delivery workflow if multi-worker needed. ";
act_prompt += "Report {done, phase, notes, evidence_gain, next, pathway_id, signposts}.";
let r4 = agent(act_prompt, #{
    label: "eva-actorask",
    capability_mode: "read-write",
    output_schema: report_schema,
    max_turns: 8,
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
