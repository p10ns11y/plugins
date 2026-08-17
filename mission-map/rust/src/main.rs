use mission_map_graph::compare;
use mission_map_graph::dag::{self, MapFile};
use mission_map_graph::ffi;
use mission_map_graph::heading;
use mission_map_graph::mermaid;
use std::env;
use std::fs;
use std::process;

fn main() {
    let (path, show_mermaid, compare_path) = parse_args();
    let map = load_map(&path);
    let report = dag::report(&map).unwrap_or_else(|e| {
        eprintln!("map: {e:?}");
        process::exit(1);
    });
    print_report(&map, &report);
    if let Some(then_path) = compare_path {
        let then_map = load_map(&then_path);
        let then = dag::report(&then_map).unwrap_or_else(|e| {
            eprintln!("compare map: {e:?}");
            process::exit(1);
        });
        let delta = compare::compare(&then_map, &then, &map, &report);
        println!("path_te_was={:.6}", delta.path_te_was);
        println!("path_te_now={:.6}", delta.path_te_now);
        println!("delta_te={:.6}", delta.delta_te);
        if !delta.completed.is_empty() {
            println!("completed={}", delta.completed.join(","));
        }
    }
    if show_mermaid {
        println!("--- mermaid");
        print!("{}", mermaid::flowchart(&map, &report));
    }
}

fn print_report(map: &MapFile, report: &dag::CriticalReport) {
    println!("g={}", report.g);
    println!("critical={}", report.critical.join(" -> "));
    println!("path_te={:.6}", report.path_te);
    if let Some(next) = &report.next_do {
        println!("next_do={next}");
    }
    let h = heading::heading(map, report);
    println!("heading={}", h.kind.as_str());
    match h.cos {
        Some(c) => println!("cos={c}"),
        None => println!("cos="),
    }
    if !h.residual.is_empty() {
        println!("residual={} -> G", h.residual.join(" -> "));
    }
    if !h.parked.is_empty() {
        println!("parked={}", h.parked.join(","));
    }
    if let Ok(stages) = dag::path_stages(map, &report.critical) {
        if !stages.is_empty() {
            if let Ok(mc) = ffi::mc_path(&stages, 1024, 1) {
                println!(
                    "mc_mean={:.6} mc_p50={:.6} mc_p90={:.6}",
                    mc.mean, mc.p50, mc.p90
                );
            }
        }
    }
}

fn load_map(path: &str) -> MapFile {
    let raw = fs::read_to_string(path).unwrap_or_else(|e| {
        eprintln!("read {path}: {e}");
        process::exit(1);
    });
    serde_json::from_str(&raw).unwrap_or_else(|e| {
        eprintln!("json {path}: {e}");
        process::exit(1);
    })
}

fn parse_args() -> (String, bool, Option<String>) {
    let mut mermaid = false;
    let mut compare_path = None;
    let mut path = None;
    let mut args = env::args().skip(1);
    while let Some(a) = args.next() {
        match a.as_str() {
            "--mermaid" => mermaid = true,
            "--compare" => {
                compare_path = Some(args.next().unwrap_or_else(|| usage()));
            }
            "-h" | "--help" => usage(),
            p if !p.starts_with('-') => path = Some(p.to_string()),
            _ => usage(),
        }
    }
    (path.unwrap_or_else(|| usage()), mermaid, compare_path)
}

fn usage() -> ! {
    eprintln!("usage: mission-map-graph <map.json> [--mermaid] [--compare <then.json>]");
    process::exit(2);
}
