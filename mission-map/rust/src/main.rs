use mission_map_graph::dag::{self, MapFile};
use mission_map_graph::ffi;
use std::env;
use std::fs;
use std::process;

fn main() {
    let path = env::args().nth(1).unwrap_or_else(usage);
    let raw = fs::read_to_string(&path).unwrap_or_else(|e| {
        eprintln!("read {path}: {e}");
        process::exit(1);
    });
    let map: MapFile = serde_json::from_str(&raw).unwrap_or_else(|e| {
        eprintln!("json: {e}");
        process::exit(1);
    });
    let report = dag::report(&map).unwrap_or_else(|e| {
        eprintln!("map: {e:?}");
        process::exit(1);
    });
    println!("g={}", report.g);
    println!("critical={}", report.critical.join(" -> "));
    println!("path_te={:.6}", report.path_te);
    if let Some(next) = &report.next_do {
        println!("next_do={next}");
    }
    if let Ok(stages) = dag::path_stages(&map, &report.critical) {
        if let Ok(mc) = ffi::mc_path(&stages, 1024, 1) {
            println!("mc_mean={:.6} mc_p50={:.6} mc_p90={:.6}", mc.mean, mc.p50, mc.p90);
        }
    }
}

fn usage() -> String {
    eprintln!("usage: mission-map-graph <map.json>");
    process::exit(2);
}
