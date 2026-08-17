//! Delta between two maps (same G). Weeks of remaining path_te, not a destiny date.

use crate::dag::{class_kind, ClassKind, CriticalReport, MapFile};

#[derive(Debug, Clone)]
pub struct Compare {
    pub path_te_was: f64,
    pub path_te_now: f64,
    pub delta_te: f64,
    pub completed: Vec<String>,
}

pub fn compare(then_map: &MapFile, then: &CriticalReport, now_map: &MapFile, now: &CriticalReport) -> Compare {
    let then_done: std::collections::HashSet<&str> = then_map
        .stages
        .iter()
        .filter(|s| class_kind(&s.class) == ClassKind::Done)
        .map(|s| s.id.as_str())
        .collect();
    let mut completed: Vec<String> = now_map
        .stages
        .iter()
        .filter(|s| class_kind(&s.class) == ClassKind::Done && !then_done.contains(s.id.as_str()))
        .map(|s| s.id.clone())
        .collect();
    completed.sort();
    Compare {
        path_te_was: then.path_te,
        path_te_now: now.path_te,
        delta_te: now.path_te - then.path_te,
        completed,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dag::{report, StageIn};

    fn pack_open() -> MapFile {
        MapFile {
            g: "g".into(),
            stages: vec![
                StageIn {
                    id: "pack".into(),
                    a: 0.5,
                    m: 1.0,
                    b: 2.0,
                    depends_on: vec![],
                    class: "Do".into(),
                },
                StageIn {
                    id: "interview".into(),
                    a: 2.0,
                    m: 4.0,
                    b: 8.0,
                    depends_on: vec!["pack".into()],
                    class: "Wait".into(),
                },
            ],
        }
    }

    #[test]
    fn done_pack_cuts_remaining_te() {
        let then = pack_open();
        let mut now = pack_open();
        now.stages[0].class = "Done".into();
        let tr = report(&then).expect("then");
        let nr = report(&now).expect("now");
        let c = compare(&then, &tr, &now, &nr);
        assert_eq!(c.completed, vec!["pack"]);
        assert!(c.delta_te < 0.0);
        assert!(c.path_te_now < c.path_te_was);
    }
}
