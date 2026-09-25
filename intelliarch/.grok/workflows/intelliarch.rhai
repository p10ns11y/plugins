// IntelliArch — host-owned background workflow (Rhai).
// Install (required — plugins do NOT auto-register .rhai):
//   cp intelliarch/.grok/workflows/intelliarch.rhai ~/.grok/workflows/
//   # or: <repo>/.grok/workflows/
// Launch: /workflow intelliarch {"goal":"…"}
// Interactive: /intelliarch
// Skills: read from https://github.com/p10ns11y/skills and sibling plugins. Do not inline bodies.

let meta = #{
    name: "intelliarch",
    description: "Feed, pstack-map, control-graph, emptiness and judgment only when they fire",
    phases: [
        #{ title: "Feed", detail: "control-feeder rewrite and one route" },
        #{ title: "Map", detail: "pstack-map then pstack or house" },
        #{ title: "Card", detail: "control-graph Outer when multi-step" },
        #{ title: "Inner", detail: "eva-emptiness only if the emptiness gate fires" },
        #{ title: "Judge", detail: "odysseus-navigator on plan or review" },
        #{ title: "Verify", detail: "real commands, fresh review context" },
    ],
    when_to_use: "engineering work that should use pstack and house guards together",
};

let goal = if args == () { () } else { args.goal };
if goal == () {
    pause("verification", "Pass args.goal — one sentence.");
}

phase("Feed");
let feed = "";
feed += "Read control-feeder/SKILL.md from https://github.com/p10ns11y/skills (master). Rewrite the dump. Emit Feed. ";
feed += "Goal: " + goal + ". ";
feed += "Route light, cg-outer, or eva-inner. Do not open a Card on the raw dump.";
let feed_out = prompt(feed);

phase("Map");
let map_prompt = "";
map_prompt += "Read pstack-map/skills/pstack-map/SKILL.md and references/map.md from https://github.com/p10ns11y/plugins. ";
map_prompt += "Prior feed: " + feed_out + ". ";
map_prompt += "If pstack poteto-mode is installed, load that playbook. Else the house skill named on the row. ";
map_prompt += "Do not paste playbook bodies. Credit Lauren Tan / pstack MIT. ";
map_prompt += "HITL if secrets, prod, irreversible git, CV, or unknown auth.";
let map_out = prompt(map_prompt);

phase("Card");
let card_prompt = "";
card_prompt += "Read control-graph/SKILL.md from https://github.com/p10ns11y/skills. ";
card_prompt += "If the map route is light, skip the Card and say why. ";
card_prompt += "Else open a Card: phase, budgets, verify commands, model_role. ";
card_prompt += "Map: " + map_out;
let card_out = prompt(card_prompt);

phase("Inner");
let inner_prompt = "";
inner_prompt += "Read eva-emptiness/SKILL.md from https://github.com/p10ns11y/skills only to apply the emptiness gate. ";
inner_prompt += "If the path is already clear, skip and say so. ";
inner_prompt += "If the gate fires, run Prior to ActOrAsk. Stay on ask. ";
inner_prompt += "Card: " + card_out;
let inner_out = prompt(inner_prompt);

phase("Judge");
let judge_prompt = "";
judge_prompt += "Read odysseus-navigator/SKILL.md from https://github.com/p10ns11y/skills. ";
judge_prompt += "If this is a plan or review, emit Navigator: one mistake or none, one next. ";
judge_prompt += "Inner: " + inner_out;
let judge_out = prompt(judge_prompt);

phase("Verify");
let verify_prompt = "";
verify_prompt += "Run the verify commands on the Card. Review in a fresh context. ";
verify_prompt += "Judge: " + judge_out + ". ";
verify_prompt += "Report phase, done, risks. Do not claim a pass you did not run.";
prompt(verify_prompt);
