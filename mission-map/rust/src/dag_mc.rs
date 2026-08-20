//! DAG-aware Monte Carlo: sample stage durations, recompute longest path each draw.

use crate::dag::{class_kind, ClassKind, MapError, MapFile, MAX_STAGES};
use crate::ffi::MmStage;
use rand::{Rng, SeedableRng};
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct DagMcSummary {
    pub mean: f64,
    pub p50: f64,
    pub p90: f64,
    pub critical_freq: HashMap<String, f64>,
}

pub fn dag_mc(map: &MapFile, draws: u32, seed: u64) -> Result<DagMcSummary, MapError> {
    use crate::dag::{index_ids, pred_lists, topo_order};
    if map.stages.is_empty() {
        return Err(MapError::Empty);
    }
    if map.stages.len() > MAX_STAGES {
        return Err(MapError::TooMany);
    }
    let index = index_ids(&map.stages)?;
    let preds = pred_lists(&map.stages, &index)?;
    let order = topo_order(&map.stages, &preds)?;
    let n = map.stages.len();
    let mut rng = rand::rngs::StdRng::seed_from_u64(seed);
    let mut totals = Vec::with_capacity(draws as usize);
    let mut crit_counts = vec![0u32; n];

    for _ in 0..draws {
        let mut tes = vec![0.0; n];
        for (i, s) in map.stages.iter().enumerate() {
            if class_kind(&s.class) == ClassKind::Done {
                tes[i] = 0.0;
            } else {
                let unit: f64 = rng.random();
                tes[i] = sample_triangular(MmStage {
                    a: s.a,
                    m: s.m,
                    b: s.b,
                }, unit);
            }
        }
        let (dist, parent) = longest_from_start(&preds, &tes, &order);
        let sink = argmax(&dist);
        totals.push(dist[sink]);
        for idx in walk_parents_indices(parent, sink) {
            crit_counts[idx] += 1;
        }
    }

    totals.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
    let mean = totals.iter().sum::<f64>() / draws as f64;
    let p50 = totals[(draws as usize - 1) / 2];
    let p90 = totals[(9 * (draws as usize - 1)) / 10];
    let mut critical_freq = HashMap::new();
    for (i, s) in map.stages.iter().enumerate() {
        critical_freq.insert(s.id.clone(), crit_counts[i] as f64 / draws as f64);
    }
    Ok(DagMcSummary {
        mean,
        p50,
        p90,
        critical_freq,
    })
}

fn sample_triangular(stage: MmStage, unit: f64) -> f64 {
    let span = stage.b - stage.a;
    if span <= 0.0 {
        return stage.a;
    }
    let left = stage.m - stage.a;
    let right = stage.b - stage.m;
    let fc = left / span;
    if unit < fc {
        stage.a + (unit * span * left).sqrt()
    } else {
        stage.b - ((1.0 - unit) * span * right).sqrt()
    }
}

fn longest_from_start(
    preds: &[Vec<usize>],
    tes: &[f64],
    order: &[usize],
) -> (Vec<f64>, Vec<Option<usize>>) {
    let n = tes.len();
    let mut dist = vec![0.0; n];
    let mut parent = vec![None; n];
    for &v in order {
        let mut best_pred = 0.0;
        let mut best_p = None;
        for &p in &preds[v] {
            if dist[p] >= best_pred {
                best_pred = dist[p];
                best_p = Some(p);
            }
        }
        dist[v] = best_pred + tes[v];
        parent[v] = best_p;
    }
    (dist, parent)
}

fn argmax(dist: &[f64]) -> usize {
    let mut best = 0;
    for i in 1..dist.len() {
        if dist[i] > dist[best] {
            best = i;
        }
    }
    best
}

fn walk_parents_indices(parent: Vec<Option<usize>>, sink: usize) -> Vec<usize> {
    let mut chain = Vec::new();
    let mut cur = Some(sink);
    while let Some(i) = cur {
        chain.push(i);
        cur = parent[i];
    }
    chain
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dag::{report, StageIn};

    #[test]
    fn dag_mc_on_sample_map() {
        let map = MapFile {
            g: "g".into(),
            stages: vec![
                StageIn {
                    id: "pack".into(),
                    a: 0.5,
                    m: 1.0,
                    b: 2.0,
                    depends_on: vec![],
                    class: "Do".into(),
                    what: String::new(),
                    lambda: None,
                    blast: None,
                },
                StageIn {
                    id: "interview".into(),
                    a: 2.0,
                    m: 4.0,
                    b: 8.0,
                    depends_on: vec!["pack".into()],
                    class: "Wait".into(),
                    what: String::new(),
                    lambda: None,
                    blast: None,
                },
            ],
        };
        let r = report(&map).expect("report");
        let mc = dag_mc(&map, 256, 42).expect("dag_mc");
        assert!(mc.p50 > r.path_te * 0.5);
        assert!(mc.p90 >= mc.p50);
        assert!(mc.critical_freq.get("pack").copied().unwrap_or(0.0) > 0.9);
    }
}
