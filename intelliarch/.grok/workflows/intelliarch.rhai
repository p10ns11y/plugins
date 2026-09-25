// IntelliArch router. Plugins do not auto-register this file.
//   cp intelliarch/.grok/workflows/intelliarch.rhai ~/.grok/workflows/
// Launch: /workflow intelliarch {"goal":"…"}
// load_ids are the manifest primary and signal ids. test-thin.sh checks the set.

let meta = #{
    name: "intelliarch",
    description: "Route one goal onto at most four skills, then take one bounded step",
    phases: [
        #{ title: "Classify", detail: "one route, at most four loads" },
        #{ title: "Act", detail: "open only the chosen URLs" },
        #{ title: "Judge", detail: "one mistake when odysseus-navigator was loaded" },
        #{ title: "Verify", detail: "re-run one named test command" },
    ],
    when_to_use: "a goal that should pick pstack or a house guard instead of loading every skill",
};

fn contains(list, id) {
    let found = false;
    for item in list {
        if item == id {
            found = true;
        }
    }
    found
}

fn url_of(id, ids, urls) {
    let i = 0;
    let found = "";
    for name in ids {
        if name == id {
            found = urls[i];
        }
        i += 1;
    }
    found
}

fn unsafe_cmd(cmd) {
    let bad = false;
    if cmd.contains("push") { bad = true; }
    if cmd.contains("reset") { bad = true; }
    if cmd.contains("rm ") { bad = true; }
    if cmd.contains("curl") { bad = true; }
    if cmd.contains("wget") { bad = true; }
    if cmd.contains("sudo") { bad = true; }
    if cmd.contains("chmod") { bad = true; }
    if cmd.contains(">") { bad = true; }
    if cmd.contains("|") { bad = true; }
    if cmd.contains("&") { bad = true; }
    if cmd.contains(";") { bad = true; }
    if cmd.contains("`") { bad = true; }
    bad
}

fn text_or(value, fallback) {
    if type_of(value) == "string" {
        value.trim();
        if value != "" {
            value
        } else {
            fallback
        }
    } else {
        fallback
    }
}

let load_ids = [
    "control-feeder",
    "eva-emptiness",
    "control-graph",
    "pstack-map",
    "odysseus-navigator",
    "ai-optimization",
    "agent-orchestrator",
    "git-worktrees",
    "adversarial-audit",
    "pulse-memory",
    "mission-map",
    "uncertainty-laws",
    "layout-content-view",
    "premflow",
    "arch-machine",
    "peram_senior_mlai_engineer",
];

let load_urls = [
    "https://raw.githubusercontent.com/p10ns11y/skills/master/control-feeder/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/plugins/main/eva-emptiness/skills/eva-emptiness/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/skills/master/control-graph/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/plugins/main/pstack-map/skills/pstack-map/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/skills/master/odysseus-navigator/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/skills/master/ai-optimization/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/skills/master/agent-orchestrator/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/skills/master/git-worktrees/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/skills/master/adversarial-audit/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/plugins/main/pulse-memory/skills/pulse-memory/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/plugins/main/mission-map/skills/mission-map/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/plugins/main/uncertainty-laws/skills/uncertainty-laws/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/plugins/main/layout-content-view/skills/layout-content-view/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/plugins/main/premflow/skills/premflow/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/plugins/main/arch-machine/skills/arch-machine/SKILL.md",
    "https://raw.githubusercontent.com/p10ns11y/skills/master/peram_senior_mlai_engineer/SKILL.md",
];

let classify_schema = #{
    "type": "object",
    "required": ["situation", "route", "loads", "playbook", "hitl", "feeder"],
    "properties": #{
        "situation": #{ "type": "string" },
        "route": #{ "type": "string" },
        "loads": #{ "type": "array", "maxItems": 4, "items": #{ "type": "string" } },
        "playbook": #{ "type": "string" },
        "hitl": #{ "type": "string" },
        "feeder": #{ "type": "boolean" },
    },
};

let act_schema = #{
    "type": "object",
    "required": ["situation", "next", "verify_cmd", "acted"],
    "properties": #{
        "situation": #{ "type": "string" },
        "next": #{ "type": "string" },
        "verify_cmd": #{ "type": "string" },
        "acted": #{ "type": "string" },
    },
};

let judge_schema = #{
    "type": "object",
    "required": ["mistake", "next"],
    "properties": #{
        "mistake": #{ "type": "string" },
        "next": #{ "type": "string" },
    },
};

let verify_schema = #{
    "type": "object",
    "required": ["passed", "evidence"],
    "properties": #{
        "passed": #{ "type": "boolean" },
        "evidence": #{ "type": "string" },
    },
};

let goal = if args == () { () } else { args.goal };
if type_of(goal) != "string" {
    pause("verification", "Pass args.goal — one sentence.");
}
goal.trim();
if goal == "" {
    pause("verification", "Pass args.goal — one sentence.");
}
let route_arg = if args == () { () } else { args.route };

phase("Classify");
let classify_prompt = "";
classify_prompt += "Classify this goal. Do not fetch files and do not edit anything. Decide from the goal text and this table only.\n";
classify_prompt += "Goal JSON:\n";
classify_prompt += json_encode(goal);
classify_prompt += "\n\nPrimary, first match after a dump rewrite:\n";
classify_prompt += "1. No map, unknowns dominate, or authorization is the unknown → route empty. loads include eva-emptiness.\n";
classify_prompt += "2. Multi-step, until-done, or the same step is being redone → route card. loads include control-graph.\n";
classify_prompt += "3. Otherwise → route light. loads include pstack-map.\n";
classify_prompt += "If the goal is a paste or dump with no single ask, set feeder true and include control-feeder. Otherwise feeder false.\n";
classify_prompt += "Add a signal id only when the goal shows that signal. At most four loads total.\n";
classify_prompt += "Signals: odysseus-navigator (plan, architecture, or review); ai-optimization (context already large); ";
classify_prompt += "agent-orchestrator (more than one writer); git-worktrees (parallel checkouts or a merge); ";
classify_prompt += "adversarial-audit (review, and pstack interrogate Task seats are missing); pulse-memory (notes contradict); ";
classify_prompt += "mission-map (critical path, shock, or replan); uncertainty-laws (bet, money, or a life fork); ";
classify_prompt += "layout-content-view (overflow, clip, landmarks, viewport); premflow (note, win, task, journal, focus); ";
classify_prompt += "arch-machine (host audit, thin path only); peram_senior_mlai_engineer (prose or public voice).\n";
classify_prompt += "Do not emit clt-dual-load. Do not invent ids.\n";
classify_prompt += "playbook is one of: investigation, bug-fix, perf-issue, hillclimb, runtime-forensics, trace-forensics, feature, refactoring, prototype, visual-parity, authoring-a-skill, eval, babysit, shipping, autonomous-run, orchestrate, autopilot-full, autopilot-stack, session-pickup, pause-safely, multi-phase-plan, worktree-cleanup, figure-it-out, skip.\n";
classify_prompt += "hitl is none, or a short reason if the goal needs secrets, production, irreversible git, CV promote, unknown authorization, or a money, legal, or health act.\n";

let cls = agent(classify_prompt, #{
    label: "classify",
    capability_mode: "read-only",
    output_schema: classify_schema,
});

let out = ();
if cls == () || !cls.success {
    log("Classify failed; route light, load pstack-map");
} else if type_of(cls.output) == "map" {
    out = cls.output;
} else {
    log("Classify output was not a map; route light, load pstack-map");
}

let route = "light";
if out != () && type_of(out.route) == "string" {
    if out.route == "light" || out.route == "card" || out.route == "empty" {
        route = out.route;
    } else {
        log("dropped unknown route");
    }
}
if type_of(route_arg) == "string" {
    if route_arg == "light" || route_arg == "card" || route_arg == "empty" {
        route = route_arg;
        log("route taken from args");
    } else if route_arg != "" {
        log("ignored args.route");
    }
}

let feeder = false;
if out != () && out.feeder == true {
    feeder = true;
}
let playbook = "skip";
if out != () {
    playbook = text_or(out.playbook, "skip");
}
let hitl = "none";
if out != () {
    hitl = text_or(out.hitl, "none");
}
let situation = goal;
if out != () {
    situation = text_or(out.situation, goal);
}

let raw_loads = [];
if out != () && type_of(out.loads) == "array" {
    raw_loads = out.loads;
}

let primary = "pstack-map";
if route == "card" {
    primary = "control-graph";
} else if route == "empty" {
    primary = "eva-emptiness";
}

let kept = [];
let skip_notes = [];
if feeder {
    kept.push("control-feeder");
}
if !contains(kept, primary) {
    kept.push(primary);
}
for id in raw_loads {
    let take = true;
    if type_of(id) != "string" {
        skip_notes.push("dropped a load that was not a string");
        take = false;
    } else if !contains(load_ids, id) {
        skip_notes.push("unknown " + id);
        take = false;
    } else if contains(kept, id) {
        take = false;
    } else if kept.len() >= 4 {
        skip_notes.push("over cap " + id);
        take = false;
    }
    if take {
        kept.push(id);
    }
}

let url_block = "";
for id in kept {
    url_block += id;
    url_block += " ";
    url_block += url_of(id, load_ids, load_urls);
    url_block += "\n";
}

let act_mode = "execute";
if hitl != "none" || route == "empty" {
    act_mode = "read-only";
}

phase("Act");
let act_prompt = "";
act_prompt += "Apply only the loads below. Fetch only those URLs. If a URL fails, record it and do not substitute another skill. Do not paste skill bodies.\n";
act_prompt += "Use read_file and grep on the working tree before you edit. Quote at most one sentence from a skill.\n";
act_prompt += "Goal JSON:\n";
act_prompt += json_encode(goal);
act_prompt += "\nroute: ";
act_prompt += route;
act_prompt += "\nplaybook: ";
act_prompt += playbook;
act_prompt += "\nhitl: ";
act_prompt += hitl;
act_prompt += "\nURLs:\n";
act_prompt += url_block;
act_prompt += "\nIf hitl is not none: do not edit, push, spend, or call a tool that changes the machine. next is the human ask.\n";
act_prompt += "If route is empty: write knowns, unknowns, one idk, disprove_with, and ActOrAsk. Unknown authorization stays Ask. No --always-approve and no --yolo. verify_cmd is empty.\n";
act_prompt += "If route is light: follow that one playbook. pstack poteto-mode if it is installed, otherwise the house row in pstack-map/skills/pstack-map/references/map.md. Take the first bounded step. Reversible edits may proceed.\n";
act_prompt += "If route is card: name the phase, the budget, and one verify command, then do only the current phase.\n";
act_prompt += "verify_cmd is the single test or build command you ran, or empty. It must be one command with no pipe, redirect, or chained shell.\n";
act_prompt += "acted is one sentence on what you did, or why you stopped.\n";
act_prompt += "Credit Lauren Tan / pstack MIT when playbook is not skip.\n";

let act = agent(act_prompt, #{
    label: "act",
    capability_mode: act_mode,
    output_schema: act_schema,
});

if act == () || !act.success {
    complete(#{
        summary: "Act failed",
        route: route,
        loads: kept,
        hitl: hitl,
        error: true,
    });
}

let act_out = ();
if type_of(act.output) == "map" {
    act_out = act.output;
}
let next = "stop";
let acted = "";
let verify_cmd = "";
if act_out != () {
    situation = text_or(act_out.situation, situation);
    next = text_or(act_out.next, "stop");
    acted = text_or(act_out.acted, "");
    verify_cmd = text_or(act_out.verify_cmd, "");
}

if contains(kept, "odysseus-navigator") {
    phase("Judge");
    let judge_prompt = "";
    judge_prompt += "Read only https://raw.githubusercontent.com/p10ns11y/skills/master/odysseus-navigator/SKILL.md\n";
    judge_prompt += "Emit one mistake, or none, and one next. Do not implement. Do not paste the skill.\n";
    judge_prompt += "Goal JSON:\n";
    judge_prompt += json_encode(goal);
    judge_prompt += "\nroute: ";
    judge_prompt += route;
    judge_prompt += "\nacted: ";
    judge_prompt += acted;
    judge_prompt += "\nproposed next: ";
    judge_prompt += next;
    let judge = agent(judge_prompt, #{
        label: "judge",
        capability_mode: "read-only",
        output_schema: judge_schema,
    });
    if judge != () && judge.success && type_of(judge.output) == "map" {
        let jn = text_or(judge.output.next, "");
        if jn != "" {
            next = jn;
        }
        let mistake = text_or(judge.output.mistake, "");
        if mistake != "" {
            acted += " Judge: " + mistake;
        }
    } else {
        log("Judge returned nothing usable");
    }
}

let verify_note = "not run";
if hitl == "none" && route != "empty" && verify_cmd != "" {
    if unsafe_cmd(verify_cmd) {
        log("Verify refused the command");
        verify_note = "refused";
        next = "verify command refused";
    } else {
        phase("Verify");
        let verify_prompt = "";
        verify_prompt += "Run this one command in the working tree and report whether it passed. Do not push, delete, or change the command.\n";
        verify_prompt += verify_cmd;
        let ver = agent(verify_prompt, #{
            label: "verify",
            capability_mode: "execute",
            output_schema: verify_schema,
        });
        if ver != () && ver.success && type_of(ver.output) == "map" && ver.output.passed == true {
            verify_note = "passed";
        } else {
            verify_note = "failed";
            next = "verify failed";
        }
    }
} else {
    log("Verify skipped");
}

let loads_line = "";
for id in kept {
    if loads_line != "" {
        loads_line += ", ";
    }
    loads_line += id;
}
let skip_line = "";
for note in skip_notes {
    if skip_line != "" {
        skip_line += "; ";
    }
    skip_line += note;
}

let report = "";
report += "# IntelliArch\n\n";
report += "| Field | Value |\n|---|---|\n";
report += "| situation | ";
report += situation;
report += " |\n| route | ";
report += route;
report += " |\n| loads | ";
report += loads_line;
report += " |\n| skips | ";
report += skip_line;
report += " |\n| playbook | ";
report += playbook;
report += " |\n| hitl | ";
report += hitl;
report += " |\n| next | ";
report += next;
report += " |\n| acted | ";
report += acted;
report += " |\n| verify | ";
report += verify_note;
report += " |\n";
let report_path = write_scratch_file("intelliarch-route.md", report);

complete(#{
    path: report_path,
    report: report,
    route: route,
    loads: kept,
    playbook: playbook,
    hitl: hitl,
    next: next,
    verify: verify_note,
});
