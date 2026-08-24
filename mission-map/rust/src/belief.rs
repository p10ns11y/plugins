//! HSMM-style regime filter on weekly compare snapshots.

use crate::compare::Compare;
use crate::dag::{class_kind, ClassKind, MapFile};
use crate::heading::{Heading, HeadingKind};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Regime {
    OnTrack,
    Slow,
    Blocked,
    Distracted,
}

impl Regime {
    pub fn as_str(&self) -> &'static str {
        match self {
            Regime::OnTrack => "on_track",
            Regime::Slow => "slow",
            Regime::Blocked => "blocked",
            Regime::Distracted => "distracted",
        }
    }
}

#[derive(Debug, Clone)]
pub struct RegimeBelief {
    pub on_track: f64,
    pub slow: f64,
    pub blocked: f64,
    pub distracted: f64,
}

const TRANS: [[f64; 4]; 4] = [
    [0.70, 0.15, 0.10, 0.05],
    [0.40, 0.35, 0.20, 0.05],
    [0.30, 0.20, 0.40, 0.10],
    [0.50, 0.10, 0.10, 0.30],
];

pub fn filter_step(
    prior: Option<&RegimeBelief>,
    compare: &Compare,
    heading: &Heading,
    now_map: &MapFile,
) -> RegimeBelief {
    let prior_vec = prior
        .map(|p| [p.on_track, p.slow, p.blocked, p.distracted])
        .unwrap_or([0.55, 0.20, 0.15, 0.10]);
    let emit = emission_likelihood(compare, heading, now_map);
    let mut post = [0.0; 4];
    for j in 0..4 {
        let mut sum = 0.0;
        for i in 0..4 {
            sum += prior_vec[i] * TRANS[i][j];
        }
        post[j] = sum * emit[j];
    }
    normalize(&mut post);
    RegimeBelief {
        on_track: post[0],
        slow: post[1],
        blocked: post[2],
        distracted: post[3],
    }
}

fn emission_likelihood(
    compare: &Compare,
    heading: &Heading,
    now_map: &MapFile,
) -> [f64; 4] {
    let mut e = [0.05, 0.05, 0.05, 0.05];
    if compare.delta_te < -0.01 && !compare.completed.is_empty() {
        e[0] += 0.75;
    }
    if compare.delta_te > 0.01 {
        e[1] += 0.45;
        if wait_on_critical(now_map, &heading.residual) {
            e[2] += 0.40;
        }
    }
    if heading.kind == HeadingKind::Park {
        e[3] += 0.70;
    }
    if heading.kind == HeadingKind::OnPath && compare.delta_te <= 0.01 {
        e[0] += 0.20;
    }
    e
}

fn wait_on_critical(now_map: &MapFile, residual: &[String]) -> bool {
    residual.iter().any(|id| {
        now_map
            .stages
            .iter()
            .find(|s| s.id == *id)
            .map(|s| class_kind(&s.class) == ClassKind::Wait)
            .unwrap_or(false)
    })
}

fn normalize(v: &mut [f64; 4]) {
    let s: f64 = v.iter().sum();
    if s > 0.0 {
        for x in v.iter_mut() {
            *x /= s;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dag::{report, StageIn};

    #[test]
    fn progress_emits_on_track() {
        let then = MapFile {
            g: "g".into(),
            stages: vec![StageIn {
                id: "pack".into(),
                a: 1.0,
                m: 2.0,
                b: 3.0,
                depends_on: vec![],
                class: "Do".into(),
                what: String::new(),
                lambda: None,
                blast: None,
            }],
        };
        let mut now = then.clone();
        now.stages[0].class = "Done".into();
        let tr = report(&then).unwrap();
        let nr = report(&now).unwrap();
        let c = crate::compare::compare(&then, &tr, &now, &nr);
        let h = crate::heading::heading(&now, &nr);
        let b = filter_step(None, &c, &h, &now);
        assert!(b.on_track > b.distracted);
    }
}
