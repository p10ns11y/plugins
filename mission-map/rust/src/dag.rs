//! Owns the mission DAG, topo order, and critical path.

use crate::ffi::{self, MmStage};
use serde::Deserialize;
use std::collections::{HashMap, VecDeque};

pub const MAX_STAGES: usize = 32;

#[derive(Debug, Deserialize, Clone)]
pub struct StageIn {
    pub id: String,
    pub a: f64,
    pub m: f64,
    pub b: f64,
    #[serde(default)]
    pub depends_on: Vec<String>,
    #[serde(default)]
    pub class: String,
    /// Public-safe short label. Empty = id only. Never put amounts or case IDs here.
    #[serde(default)]
    pub what: String,
    /// Risk hazard λ (events per week). Risk class only.
    #[serde(default)]
    pub lambda: Option<f64>,
    /// Weeks added to T if Risk fires. Risk class only.
    #[serde(default)]
    pub blast: Option<f64>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct MapFile {
    pub g: String,
    pub stages: Vec<StageIn>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ClassKind {
    Do,
    Wait,
    Park,
    Done,
    Risk,
    Other,
}

pub fn class_kind(raw: &str) -> ClassKind {
    match raw.trim().to_ascii_lowercase().as_str() {
        "do" => ClassKind::Do,
        "wait" => ClassKind::Wait,
        "park" => ClassKind::Park,
        "done" => ClassKind::Done,
        "risk" => ClassKind::Risk,
        _ => ClassKind::Other,
    }
}

#[derive(Debug, Clone)]
pub struct CriticalReport {
    pub g: String,
    pub order: Vec<String>,
    pub critical: Vec<String>,
    pub path_te: f64,
    pub next_do: Option<String>,
}

#[derive(Debug)]
pub enum MapError {
    Empty,
    TooMany,
    UnknownDep(String),
    Cycle,
    Pert(i32),
}

pub fn report(map: &MapFile) -> Result<CriticalReport, MapError> {
    if map.stages.is_empty() {
        return Err(MapError::Empty);
    }
    if map.stages.len() > MAX_STAGES {
        return Err(MapError::TooMany);
    }

    let index = index_ids(&map.stages)?;
    let preds = pred_lists(&map.stages, &index)?;
    let order_idx = topo_order(&map.stages, &preds)?;
    let tes = stage_tes(&map.stages)?;
    let (dist, parent) = longest_from_start(&preds, &tes, &order_idx);
    let sink = argmax(&dist);
    let critical_idx = walk_parents(parent, sink);
    let order: Vec<String> = order_idx.iter().map(|&i| map.stages[i].id.clone()).collect();
    let critical: Vec<String> = critical_idx
        .iter()
        .map(|&i| map.stages[i].id.clone())
        .collect();
    let next_do = pick_next_do(map, &critical);

    Ok(CriticalReport {
        g: map.g.clone(),
        order,
        critical,
        path_te: dist[sink],
        next_do,
    })
}

fn pick_next_do(map: &MapFile, critical: &[String]) -> Option<String> {
    for id in critical {
        if let Some(s) = map.stages.iter().find(|s| s.id == *id) {
            if class_kind(&s.class) == ClassKind::Do {
                return Some(s.id.clone());
            }
        }
    }
    map.stages
        .iter()
        .find(|s| class_kind(&s.class) == ClassKind::Do)
        .map(|s| s.id.clone())
}

pub fn path_stages(map: &MapFile, ids: &[String]) -> Result<Vec<MmStage>, MapError> {
    let index = index_ids(&map.stages)?;
    let mut out = Vec::with_capacity(ids.len());
    for id in ids {
        let i = *index.get(id).ok_or_else(|| MapError::UnknownDep(id.clone()))?;
        let s = &map.stages[i];
        if class_kind(&s.class) == ClassKind::Done {
            continue;
        }
        out.push(MmStage {
            a: s.a,
            m: s.m,
            b: s.b,
        });
    }
    Ok(out)
}

pub(crate) fn index_ids(stages: &[StageIn]) -> Result<HashMap<String, usize>, MapError> {
    let mut index = HashMap::new();
    for (i, s) in stages.iter().enumerate() {
        index.insert(s.id.clone(), i);
    }
    Ok(index)
}

pub(crate) fn pred_lists(
    stages: &[StageIn],
    index: &HashMap<String, usize>,
) -> Result<Vec<Vec<usize>>, MapError> {
    let mut preds = vec![Vec::new(); stages.len()];
    for (i, s) in stages.iter().enumerate() {
        for dep in &s.depends_on {
            let p = *index
                .get(dep)
                .ok_or_else(|| MapError::UnknownDep(dep.clone()))?;
            preds[i].push(p);
        }
    }
    Ok(preds)
}

pub(crate) fn topo_order(stages: &[StageIn], preds: &[Vec<usize>]) -> Result<Vec<usize>, MapError> {
    let n = stages.len();
    let mut indeg = vec![0usize; n];
    let mut succ: Vec<Vec<usize>> = vec![Vec::new(); n];
    for (v, ps) in preds.iter().enumerate() {
        indeg[v] = ps.len();
        for &p in ps {
            succ[p].push(v);
        }
    }
    let mut q: VecDeque<usize> = (0..n).filter(|&i| indeg[i] == 0).collect();
    let mut order = Vec::with_capacity(n);
    while let Some(u) = q.pop_front() {
        order.push(u);
        for &v in &succ[u] {
            indeg[v] -= 1;
            if indeg[v] == 0 {
                q.push_back(v);
            }
        }
    }
    if order.len() != n {
        return Err(MapError::Cycle);
    }
    Ok(order)
}

fn stage_tes(stages: &[StageIn]) -> Result<Vec<f64>, MapError> {
    let mut tes = Vec::with_capacity(stages.len());
    for s in stages {
        if class_kind(&s.class) == ClassKind::Done {
            tes.push(0.0);
            continue;
        }
        let te = ffi::pert_expected(MmStage {
            a: s.a,
            m: s.m,
            b: s.b,
        })
        .map_err(MapError::Pert)?;
        tes.push(te);
    }
    Ok(tes)
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

fn walk_parents(parent: Vec<Option<usize>>, sink: usize) -> Vec<usize> {
    let mut chain = Vec::new();
    let mut cur = Some(sink);
    while let Some(i) = cur {
        chain.push(i);
        cur = parent[i];
    }
    chain.reverse();
    chain
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> MapFile {
        MapFile {
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
                StageIn {
                    id: "park".into(),
                    a: 1.0,
                    m: 1.0,
                    b: 1.0,
                    depends_on: vec![],
                    class: "Park".into(),
                    what: String::new(),
                    lambda: None,
                    blast: None,
                },
            ],
        }
    }

    #[test]
    fn critical_is_pack_then_interview() {
        let r = report(&sample()).expect("report");
        assert_eq!(r.critical, vec!["pack", "interview"]);
        assert_eq!(r.next_do.as_deref(), Some("pack"));
        assert!(r.path_te > 4.0);
        assert!(r.path_te < 7.0);
    }

    #[test]
    fn next_do_skips_done_and_wait() {
        let mut map = sample();
        map.stages[0].class = "Done".into();
        let r = report(&map).expect("report");
        assert_eq!(r.next_do.as_deref(), None);
        assert!(r.path_te < 5.0);
    }

    #[test]
    fn next_do_picks_parallel_do_when_critical_is_wait() {
        let mut map = sample();
        map.stages[0].class = "Done".into();
        map.stages[2].class = "Do".into();
        let r = report(&map).expect("report");
        assert_eq!(r.next_do.as_deref(), Some("park"));
    }

    #[test]
    fn cycle_is_error() {
        let mut map = sample();
        map.stages[0].depends_on = vec!["interview".into()];
        assert!(matches!(report(&map), Err(MapError::Cycle)));
    }
}
