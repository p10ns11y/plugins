// Portable dependency / supply-chain hardening — real skills only.
// Skills: fix-dependency-security → fix-dependency-security → upgrade-packages → audit-allow-builds

let meta = #{
    name: "dependency-harden",
    description: "Audit, fix vulns, harden pnpm workspace, safe upgrades, allowBuilds audit",
    phases: [
        #{ title: "Audit", detail: "read lockfile + pnpm audit" },
        #{ title: "Fix", detail: "vulns and deprecations safely" },
        #{ title: "Harden", detail: "workspace + sfw / supply-chain rules" },
        #{ title: "Upgrade", detail: "safe major/minor/patch with codemods" },
        #{ title: "Lifecycle", detail: "audit allowBuilds / scripts" },
    ],
    when_to_use: "pnpm audit, supply-chain hardening, safe upgrades",
};

let report_schema = #{
    "type": "object",
    "required": ["done", "notes", "commands_run"],
    "properties": #{
        "done": #{ "type": "boolean" },
        "notes": #{ "type": "string" },
        "commands_run": #{ "type": "array", "items": #{ "type": "string" } },
    },
};

phase("Audit");
let a = agent(
    "Follow fix-dependency-security + fix-dependency-security (read SKILL.md). "
        + "Read package.json, pnpm-workspace.yaml, lockfile. Run pnpm audit (or document if unavailable). "
        + "Summarize critical/high vulns and deprecations. No installs yet unless skill requires read-only audit. "
        + "Report {done, notes, commands_run}.",
    #{ label: "audit", capability_mode: "execute", output_schema: report_schema },
);
if a == () || !a.success { log("Audit failed"); }

phase("Fix");
let f = agent(
    "Follow fix-dependency-security. Apply safe fixes for vulns/deprecations: overrides, bumps, allowedDeprecatedVersions. "
        + "Prefer least blast radius. Report {done, notes, commands_run}.",
    #{ label: "fix", capability_mode: "read-write", output_schema: report_schema },
);
if f == () || !f.success { log("Fix failed"); }

phase("Harden");
let h = agent(
    "Follow fix-dependency-security. Apply workspace hardening and sfw/firewall patterns from the skill. "
        + "Report {done, notes, commands_run}.",
    #{ label: "harden", capability_mode: "read-write", output_schema: report_schema },
);
if h == () || !h.success { log("Harden failed"); }

phase("Upgrade");
let u = agent(
    "Follow upgrade-packages for remaining intentional upgrades with codemods where applicable. "
        + "Do not drive-by major bumps without justification. Report {done, notes, commands_run}.",
    #{ label: "upgrade", capability_mode: "read-write", output_schema: report_schema },
);
if u == () || !u.success { log("Upgrade failed"); }

phase("Lifecycle");
let l = agent(
    "Follow audit-allow-builds. Audit allowBuilds / lifecycle scripts in lockfile; report risk and recommended allowlist. "
        + "Report {done, notes, commands_run}.",
    #{ label: "allow-builds", capability_mode: "read-only", output_schema: report_schema },
);
if l == () || !l.success { log("Lifecycle audit failed"); }

complete(#{
    summary: "Finished dependency-harden",
    skill_chain: ["fix-dependency-security", "fix-dependency-security", "upgrade-packages", "audit-allow-builds"],
    audit: a, fix: f, harden: h, upgrade: u, lifecycle: l,
});
