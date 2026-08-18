//! Heading toward G: remaining critical path vs Parks. Not a forecast.

use crate::dag::{class_kind, ClassKind, CriticalReport, MapFile};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum HeadingKind {
    OnPath,
    Wait,
    Park,
}

impl HeadingKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            HeadingKind::OnPath => "on-path",
            HeadingKind::Wait => "wait",
            HeadingKind::Park => "park",
        }
    }
}

#[derive(Debug, Clone)]
pub struct Heading {
    pub kind: HeadingKind,
    pub cos: Option<f64>,
    pub residual: Vec<String>,
    pub parked: Vec<String>,
}

pub fn heading(map: &MapFile, report: &CriticalReport) -> Heading {
    let residual: Vec<String> = report
        .critical
        .iter()
        .filter(|id| {
            map.stages
                .iter()
                .find(|s| s.id == **id)
                .map(|s| class_kind(&s.class) != ClassKind::Done)
                .unwrap_or(true)
        })
        .cloned()
        .collect();

    let parked: Vec<String> = map
        .stages
        .iter()
        .filter(|s| class_kind(&s.class) == ClassKind::Park)
        .map(|s| s.id.clone())
        .collect();

    let (kind, cos) = match report.next_do.as_deref() {
        Some(_) => (HeadingKind::OnPath, Some(1.0)),
        None if residual.iter().any(|id| {
            map.stages
                .iter()
                .find(|s| s.id == *id)
                .map(|s| class_kind(&s.class) == ClassKind::Wait)
                .unwrap_or(false)
        }) =>
        {
            (HeadingKind::Wait, None)
        }
        None => (HeadingKind::Park, Some(0.0)),
    };

    Heading {
        kind,
        cos,
        residual,
        parked,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dag::{report, StageIn};

    #[test]
    fn pack_do_is_on_path() {
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
                    what: String::new(),
                },
                StageIn {
                    id: "side".into(),
                    a: 2.0,
                    m: 4.0,
                    b: 8.0,
                    depends_on: vec![],
                    class: "Park".into(),
                    what: String::new(),
                },
            ],
        };
        let r = report(&map).expect("report");
        let h = heading(&map, &r);
        assert_eq!(h.kind, HeadingKind::OnPath);
        assert_eq!(h.cos, Some(1.0));
        assert_eq!(h.parked, vec!["side"]);
    }
}
