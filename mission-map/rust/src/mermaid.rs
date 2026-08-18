//! Mermaid heading view. Display only — no new kernel.

use crate::dag::{class_kind, ClassKind, CriticalReport, MapFile};
use std::collections::HashSet;

pub fn flowchart(map: &MapFile, report: &CriticalReport) -> String {
    let crit: HashSet<&str> = report.critical.iter().map(String::as_str).collect();
    let mut out = String::from("flowchart TB\n");
    out.push_str("  x[\"Where you are\"]\n");
    out.push_str(&format!("  G[\"Arrive: {}\"]\n", escape(&map.g)));

    for s in &map.stages {
        let label = node_label(s);
        out.push_str(&format!("  {}[\"{}\"]\n", mermaid_id(&s.id), escape(&label)));
    }

    let mut linked_from_x = HashSet::new();
    for s in &map.stages {
        if s.depends_on.is_empty() {
            let dash = class_kind(&s.class) == ClassKind::Park;
            let arrow = if dash {
                "-.->|\"skip this week\"|"
            } else {
                "-->"
            };
            out.push_str(&format!("  x {} {}\n", arrow, mermaid_id(&s.id)));
            linked_from_x.insert(s.id.as_str());
        }
        for dep in &s.depends_on {
            let on_u = crit.contains(dep.as_str()) && crit.contains(s.id.as_str());
            let arrow = if on_u {
                "-->|\"toward start\"|"
            } else {
                "-->"
            };
            out.push_str(&format!(
                "  {} {} {}\n",
                mermaid_id(dep),
                arrow,
                mermaid_id(&s.id)
            ));
        }
    }

    if let Some(last) = report.critical.iter().rev().find(|id| {
        map.stages
            .iter()
            .find(|s| s.id == **id)
            .map(|s| class_kind(&s.class) != ClassKind::Done)
            .unwrap_or(true)
    }) {
        out.push_str(&format!("  {} --> G\n", mermaid_id(last)));
    } else {
        out.push_str("  x --> G\n");
    }

    out.push_str("  classDef do fill:#1b4332,stroke:#95d5b2,color:#fff\n");
    out.push_str("  classDef wait fill:#1d3557,stroke:#a8dadc,color:#fff\n");
    out.push_str("  classDef park fill:#3d3d3d,stroke:#9a8c98,color:#ddd\n");
    out.push_str("  classDef done fill:#2d2d2d,stroke:#6c757d,color:#adb5bd\n");
    out.push_str("  classDef goal fill:#5a189a,stroke:#c77dff,color:#fff\n");
    out.push_str("  class G goal\n");

    assign_class(&mut out, map, ClassKind::Do, "do");
    assign_class(&mut out, map, ClassKind::Wait, "wait");
    assign_class(&mut out, map, ClassKind::Park, "park");
    assign_class(&mut out, map, ClassKind::Done, "done");
    out
}

fn assign_class(out: &mut String, map: &MapFile, kind: ClassKind, cls: &str) {
    let ids: Vec<String> = map
        .stages
        .iter()
        .filter(|s| class_kind(&s.class) == kind)
        .map(|s| mermaid_id(&s.id))
        .collect();
    if !ids.is_empty() {
        out.push_str(&format!("  class {} {}\n", ids.join(","), cls));
    }
}

fn node_label(s: &crate::dag::StageIn) -> String {
    let kind = match class_kind(&s.class) {
        ClassKind::Do => "do now",
        ClassKind::Wait => "waiting on them",
        ClassKind::Park => "parked",
        ClassKind::Done => "already done",
        ClassKind::Risk => "later / stretch",
        ClassKind::Other => s.class.trim(),
    };
    let what = s.what.trim();
    if what.is_empty() {
        format!("{} ({})", s.id, kind)
    } else {
        format!("{what} ({kind})")
    }
}

fn mermaid_id(id: &str) -> String {
    id.chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '_' })
        .collect()
}

fn escape(s: &str) -> String {
    s.replace('"', "'")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dag::{report, StageIn};

    #[test]
    fn emits_g_and_critical_edge() {
        let map = MapFile {
            g: "started role".into(),
            stages: vec![
                StageIn {
                    id: "pack".into(),
                    a: 0.5,
                    m: 1.0,
                    b: 2.0,
                    depends_on: vec![],
                    class: "Do".into(),
                    what: "apply pack".into(),
                },
                StageIn {
                    id: "interview".into(),
                    a: 2.0,
                    m: 4.0,
                    b: 8.0,
                    depends_on: vec!["pack".into()],
                    class: "Wait".into(),
                    what: "calendars".into(),
                },
            ],
        };
        let r = report(&map).expect("report");
        let m = flowchart(&map, &r);
        assert!(m.contains("flowchart TB"));
        assert!(m.contains("Arrive: started role"));
        assert!(m.contains("toward start"));
        assert!(m.contains("class pack do"));
        assert!(m.contains("apply pack"));
    }
}
