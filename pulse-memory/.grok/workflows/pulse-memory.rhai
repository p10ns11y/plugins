let meta = #{
    name: "pulse-memory",
    description: "Read thinking and harness state, admit sparse tagged pulse snippets, refuse dumps",
    when_to_use: "Periodic or on-demand memory pulse: inject dated sourced snippets instead of dumping transcripts. Pair with /pulse-memory.",
    phases: [
        #{ title: "Scan", detail: "read thinking + harness files" },
        #{ title: "Admit", detail: "admissions filter + conflict resolution" },
        #{ title: "Pulse", detail: "write tagged snippets" },
    ],
};

let scan_schema = #{
    "type": "object",
    "required": ["claims"],
    "properties": #{
        "claims": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["text", "source", "time", "status", "kind"],
                "properties": #{
                    "text": #{ "type": "string" },
                    "source": #{ "type": "string" },
                    "time": #{ "type": "string" },
                    "status": #{ "type": "string" },
                    "kind": #{ "type": "string" },
                    "lock": #{ "type": "string" },
                    "key": #{ "type": "string" },
                },
            },
        },
    },
};

let admit_schema = #{
    "type": "object",
    "required": ["pulses", "conflicts", "rejected"],
    "properties": #{
        "pulses": #{
            "type": "array",
            "maxItems": 8,
            "items": #{
                "type": "object",
                "required": ["key", "snippet", "source", "time", "status", "kind"],
                "properties": #{
                    "key": #{ "type": "string" },
                    "snippet": #{ "type": "string" },
                    "source": #{ "type": "string" },
                    "time": #{ "type": "string" },
                    "status": #{ "type": "string" },
                    "kind": #{ "type": "string" },
                    "lock": #{ "type": "string" },
                    "verify": #{ "type": "string" },
                    "prefetch": #{ "type": "string" },
                },
            },
        },
        "conflicts": #{
            "type": "array",
            "maxItems": 8,
            "items": #{
                "type": "object",
                "required": ["subject", "resolution"],
                "properties": #{
                    "subject": #{ "type": "string" },
                    "resolution": #{ "type": "string" },
                },
            },
        },
        "rejected": #{
            "type": "array",
            "maxItems": 12,
            "items": #{ "type": "string" },
        },
    },
};

fn trimmed(s) {
    if type_of(s) == "string" {
        s.trim();
        s
    } else {
        ""
    }
}

let thinking_path = ();
let harness_path = ();
let pulse_out = ();
let as_of = ();
let next_action = ();
if args != () {
    thinking_path = args.thinking_path;
    harness_path = args.harness_path;
    pulse_out = args.pulse_out;
    as_of = args.as_of;
    next_action = args.next_action;
}
if thinking_path == () || trimmed(thinking_path) == "" {
    pause("verification", "Pass args.thinking_path — file or dir of thinking / scratch.");
}
if harness_path == () || trimmed(harness_path) == "" {
    pause("verification", "Pass args.harness_path — file of intermediate harness state.");
}
if as_of == () || trimmed(as_of) == "" {
    pause("verification", "Pass args.as_of — ISO-8601 time (workflow has no wall clock).");
}
if next_action == () { next_action = "unknown next action"; }

let think_q = json_encode(thinking_path);
let harness_q = json_encode(harness_path);
let as_of_q = json_encode(as_of);

phase("Scan");
let scan_jobs = [];
let p_think = "";
p_think += "Read the thinking / scratch file at " + think_q + " with read_file (or list_dir then read). ";
p_think += "Do not answer from memory. Extract at most 12 claims that might affect a later action. ";
p_think += "Tag each: source (this path), time (from the file or " + as_of_q + " if unknown), ";
p_think += "status one of user-stated|tool-verified|inferred|unknown, kind one of data|context|fact|memory, ";
p_think += "lock open|locked if stated. Empty claims[] is valid only after you actually read the file. ";
p_think += "Never invent completeness. If the file is missing, return claims[] and say so in one claim text.";
scan_jobs.push(#{
    prompt: p_think,
    label: "scan:thinking",
    capability_mode: "read-only",
    output_schema: scan_schema,
});
let p_harness = "";
p_harness += "Read the harness intermediate-state file at " + harness_q + " with read_file. ";
p_harness += "Do not answer from memory. Extract at most 12 claims (tool results, paused gates, current phase). ";
p_harness += "Tag each: source, time (file mtime text or " + as_of_q + "), status, kind, lock. ";
p_harness += "Empty claims[] is valid only after you read the file or confirmed it missing.";
scan_jobs.push(#{
    prompt: p_harness,
    label: "scan:harness",
    capability_mode: "read-only",
    output_schema: scan_schema,
});
let scans = parallel(scan_jobs);

let claims = [];
for r in scans {
    if r != () && r.success && r.output.claims != () {
        for c in r.output.claims {
            claims.push(c);
        }
    }
}
log("scan claims=" + claims.len().to_string());
if claims.len() == 0 {
    let empty_path = write_scratch_file("pulse.md", "# pulse\n\nNo claims. Not in the evidence.\n");
    complete(#{ summary: "No claims after scan.", path: empty_path, pulses: 0 });
}

phase("Admit");
let claims_q = json_encode(claims);
let next_q = json_encode(next_action);
let p_admit = "";
p_admit += "You are the admissions filter from archive-not-memory. ";
p_admit += "Next action (the only reason to inject): " + next_q + ". As-of: " + as_of_q + ". ";
p_admit += "Claims JSON: " + claims_q + ". ";
p_admit += "Rules: (1) A claim is memory only if it would change that next action enough to justify bringing it back. ";
p_admit += "Otherwise put a one-line reason in rejected[]. (2) On contradictions, do not average. ";
p_admit += "Prefer later time, then status rank tool-verified > user-stated > inferred > unknown. ";
p_admit += "If still tied, resolution must be 'not in the evidence' and keep both out of pulses. ";
p_admit += "(3) pulses[].snippet max ~120 tokens; include key, source, time, status, kind, lock, verify, prefetch. ";
p_admit += "kind on pulses must be memory. status must be one of the four. ";
p_admit += "(4) Do not invent claims. Empty pulses is valid if nothing passes.";
let admitted = agent(p_admit, #{
    label: "admit",
    capability_mode: "read-only",
    output_schema: admit_schema,
});
if admitted == () || !admitted.success || admitted.output.pulses == () {
    pause("verification", "Admit step failed closed — no usable pulses.");
}

let pulses = admitted.output.pulses;
let conflicts = admitted.output.conflicts;
let rejected = admitted.output.rejected;
log("admitted=" + pulses.len().to_string());

phase("Pulse");
let md = "# memory pulse\n\n";
md += "as_of: " + trimmed(as_of) + "\n";
md += "next_action: " + trimmed(next_action) + "\n\n";
if conflicts != () {
    md += "## conflicts\n\n";
    for cf in conflicts {
        md += "- **" + trimmed(cf.subject) + "**: " + trimmed(cf.resolution) + "\n";
    }
    md += "\n";
}
md += "## pulses\n\n";
for p in pulses {
    md += "### " + trimmed(p.key) + "\n\n";
    md += "```\n";
    md += "hint:\n";
    md += "  source: " + trimmed(p.source) + "\n";
    md += "  time:   " + trimmed(p.time) + "\n";
    md += "  status: " + trimmed(p.status) + "\n";
    md += "  kind:   " + trimmed(p.kind) + "\n";
    if p.lock != () { md += "  lock:   " + trimmed(p.lock) + "\n"; }
    if p.verify != () { md += "verify:  " + trimmed(p.verify) + "\n"; }
    if p.prefetch != () { md += "prefetch:" + trimmed(p.prefetch) + "\n"; }
    md += "```\n\n";
    md += trimmed(p.snippet) + "\n\n";
}
if rejected != () && rejected.len() > 0 {
    md += "## rejected (archive)\n\n";
    for rj in rejected {
        md += "- " + trimmed(rj) + "\n";
    }
}

let report_id = write_scratch_file("pulse.md", md);

if pulse_out != () && trimmed(pulse_out) != "" {
    let out_q = json_encode(pulse_out);
    let body_q = json_encode(md);
    let p_write = "";
    p_write += "Write the pulse markdown to the path " + out_q + " using the write or search_replace file tool. ";
    p_write += "Overwrite the file with exactly this content (JSON string, decode to markdown):\n";
    p_write += body_q;
    p_write += "\nDo not add extra commentary to the file. Confirm the path you wrote.";
    let wr = agent(p_write, #{ label: "write-pulse", capability_mode: "read-write" });
    if wr == () || !wr.success {
        log("pulse_out write failed; scratch still has pulse.md");
    }
}

complete(#{
    summary: pulses.len().to_string() + " pulses",
    path: report_id,
    pulses: pulses.len(),
});
