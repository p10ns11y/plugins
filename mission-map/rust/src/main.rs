use mission_map_graph::belief;
use mission_map_graph::compare;
use mission_map_graph::dag::{self, MapFile};
use mission_map_graph::dag_mc;
use mission_map_graph::ffi;
use mission_map_graph::heading;
use mission_map_graph::mermaid;
use mission_map_graph::risk;
use std::env;
use std::fs;
use std::process;

fn main() {
    let (path, show_mermaid, compare_path, risk_tau) = parse_args();
    let map = load_map(&path);
    let report = dag::report(&map).unwrap_or_else(|e| {
        eprintln!("map: {e:?}");
        process::exit(1);
    });
    print_report(&map, &report, risk_tau);
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
        let h = heading::heading(&map, &report);
        let regime = belief::filter_step(None, &delta, &h, &map);
        println!(
            "regime_on_track={:.4} regime_slow={:.4} regime_blocked={:.4} regime_distracted={:.4}",
            regime.on_track, regime.slow, regime.blocked, regime.distracted
        );
    }
    if show_mermaid {
        println!("--- mermaid");
        print!("{}", mermaid::flowchart(&map, &report));
    }
}

fn print_report(map: &MapFile, report: &dag::CriticalReport, risk_tau: f64) {
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
    if let Ok(dag_mc) = dag_mc::dag_mc(map, 1024, 1) {
        println!(
            "dag_mc_mean={:.6} dag_mc_p50={:.6} dag_mc_p90={:.6}",
            dag_mc.mean, dag_mc.p50, dag_mc.p90
        );
        for (id, freq) in &dag_mc.critical_freq {
            if *freq >= 0.25 {
                println!("critical_prob {id}={freq:.4}");
            }
        }
    }
    let risks = risk::rank_risks(map, risk_tau);
    for r in risks {
        println!(
            "risk id={} p_fire={:.4} e_delta_te={:.4}",
            r.id, r.p_fire, r.e_delta_te
        );
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

fn parse_args() -> (String, bool, Option<String>, f64) {
    let mut mermaid = false;
    let mut compare_path = None;
    let mut risk_tau = 4.0;
    let mut path = None;
    let mut args = env::args().skip(1);
    while let Some(a) = args.next() {
        match a.as_str() {
            "--mermaid" => mermaid = true,
            "--compare" => {
                compare_path = Some(args.next().unwrap_or_else(|| usage()));
            }
            "--risk-tau" => {
                risk_tau = args
                    .next()
                    .unwrap_or_else(|| usage())
                    .parse()
                    .unwrap_or_else(|_| usage());
            }
            "-h" | "--help" => usage(),
            p if !p.starts_with('-') => path = Some(p.to_string()),
            _ => usage(),
        }
    }
    (path.unwrap_or_else(|| usage()), mermaid, compare_path, risk_tau)
}

fn usage() -> ! {
    eprintln!(
        "usage: mission-map-graph <map.json> [--mermaid] [--compare <then.json>] [--risk-tau <weeks>]"
    );
    process::exit(2);
}
