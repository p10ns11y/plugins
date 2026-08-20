//! Risk hazard ranking: P(fire by tau) and E[delta_T] per Risk stage.

use crate::dag::{class_kind, ClassKind, MapFile};

const DEFAULT_LAMBDA: f64 = 0.05;
const DEFAULT_BLAST: f64 = 2.0;
const DEFAULT_TAU: f64 = 4.0;

#[derive(Debug, Clone)]
pub struct RiskRank {
    pub id: String,
    pub lambda: f64,
    pub blast: f64,
    pub tau: f64,
    pub p_fire: f64,
    pub e_delta_te: f64,
}

pub fn rank_risks(map: &MapFile, tau: f64) -> Vec<RiskRank> {
    let tau = if tau > 0.0 { tau } else { DEFAULT_TAU };
    let mut risks: Vec<RiskRank> = map
        .stages
        .iter()
        .filter(|s| class_kind(&s.class) == ClassKind::Risk)
        .map(|s| {
            let lambda = s.lambda.unwrap_or(DEFAULT_LAMBDA);
            let blast = s.blast.unwrap_or(DEFAULT_BLAST);
            let p_fire = 1.0 - (-lambda * tau).exp();
            let e_delta_te = blast * p_fire;
            RiskRank {
                id: s.id.clone(),
                lambda,
                blast,
                tau,
                p_fire,
                e_delta_te,
            }
        })
        .collect();
    risks.sort_by(|a, b| {
        b.e_delta_te
            .partial_cmp(&a.e_delta_te)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    risks
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dag::StageIn;

    #[test]
    fn ranks_by_expected_damage() {
        let map = MapFile {
            g: "g".into(),
            stages: vec![
                StageIn {
                    id: "low".into(),
                    a: 1.0,
                    m: 2.0,
                    b: 3.0,
                    depends_on: vec![],
                    class: "Risk".into(),
                    what: String::new(),
                    lambda: Some(0.01),
                    blast: Some(1.0),
                },
                StageIn {
                    id: "high".into(),
                    a: 1.0,
                    m: 2.0,
                    b: 3.0,
                    depends_on: vec![],
                    class: "Risk".into(),
                    what: String::new(),
                    lambda: Some(0.5),
                    blast: Some(5.0),
                },
            ],
        };
        let ranked = rank_risks(&map, 4.0);
        assert_eq!(ranked[0].id, "high");
        assert!(ranked[0].e_delta_te > ranked[1].e_delta_te);
    }
}
