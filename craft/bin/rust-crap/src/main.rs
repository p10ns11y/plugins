use std::collections::{HashMap, HashSet};
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Output};

use syn::visit::Visit;
use syn::{BinOp, Block, Expr, ImplItem, Item, ItemFn, Stmt, Type};

struct Function {
    name: String,
    comp: u32,
    start: usize,
    end: usize,
}

struct Args {
    limit: f64,
    json: bool,
    functions: Option<String>,
    git_range: Option<String>,
    lib: PathBuf,
    test: PathBuf,
}

struct Counter {
    score: u32,
}

impl<'ast> Visit<'ast> for Counter {
    fn visit_expr(&mut self, expr: &'ast Expr) {
        match expr {
            Expr::If(_) | Expr::While(_) | Expr::Loop(_) | Expr::ForLoop(_) => self.score += 1,
            Expr::Binary(bin) if matches!(bin.op, BinOp::And(_) | BinOp::Or(_)) => self.score += 1,
            _ => {}
        }
        syn::visit::visit_expr(self, expr);
    }

    fn visit_arm(&mut self, arm: &'ast syn::Arm) {
        self.score += 1;
        syn::visit::visit_arm(self, arm);
    }

    fn visit_item_fn(&mut self, _: &'ast ItemFn) {}

    fn visit_impl_item_fn(&mut self, _: &'ast syn::ImplItemFn) {}
}

fn complexity(block: &Block) -> u32 {
    let mut counter = Counter { score: 1 };
    counter.visit_block(block);
    counter.score
}

fn line_of(span: proc_macro2::Span) -> usize {
    span.start().line
}

fn end_line(span: proc_macro2::Span) -> usize {
    span.end().line
}

fn join_name(prefix: &str, name: &str) -> String {
    if prefix.is_empty() {
        name.to_string()
    } else {
        format!("{prefix}.{name}")
    }
}

fn type_label(ty: &Type) -> String {
    match ty {
        Type::Path(path) => path
            .path
            .segments
            .last()
            .map(|segment| segment.ident.to_string())
            .unwrap_or_default(),
        Type::Reference(reference) => type_label(&reference.elem),
        Type::Group(group) => type_label(&group.elem),
        _ => String::new(),
    }
}

fn push_fn(func: &ItemFn, prefix: &str, out: &mut Vec<Function>) {
    let name = join_name(prefix, &func.sig.ident.to_string());
    out.push(Function {
        comp: complexity(&func.block),
        start: line_of(func.sig.ident.span()),
        end: end_line(func.block.brace_token.span.join()),
        name: name.clone(),
    });
    walk_block(&func.block, &name, out);
}

fn walk_block(block: &Block, prefix: &str, out: &mut Vec<Function>) {
    for stmt in &block.stmts {
        if let Stmt::Item(Item::Fn(func)) = stmt {
            push_fn(func, prefix, out);
        }
    }
}

fn walk_items(items: &[Item], prefix: &str, out: &mut Vec<Function>) {
    for item in items {
        match item {
            Item::Fn(func) => push_fn(func, prefix, out),
            Item::Mod(module) => {
                if let Some((_, nested)) = &module.content {
                    walk_items(nested, &join_name(prefix, &module.ident.to_string()), out);
                }
            }
            Item::Impl(item) => {
                let label = type_label(&item.self_ty);
                for member in &item.items {
                    let ImplItem::Fn(method) = member else { continue };
                    let name = join_name(&label, &method.sig.ident.to_string());
                    out.push(Function {
                        comp: complexity(&method.block),
                        start: line_of(method.sig.ident.span()),
                        end: end_line(method.block.brace_token.span.join()),
                        name: name.clone(),
                    });
                    walk_block(&method.block, &name, out);
                }
            }
            _ => {}
        }
    }
}

fn functions_in(source: &str) -> Result<Vec<Function>, String> {
    let file = syn::parse_file(source).map_err(|error| format!("rust parse failed: {error}"))?;
    let mut found = Vec::new();
    walk_items(&file.items, "", &mut found);
    if found.is_empty() {
        return Err("no functions".to_string());
    }
    Ok(found)
}

fn crap(comp: f64, cov: f64) -> f64 {
    comp.powi(2) * (1.0 - cov).powi(3) + comp
}

fn sanitize(text: &str) -> String {
    let mut out = String::new();
    for word in text.split_whitespace() {
        if word.contains("/home/") || word.contains("/Users/") {
            out.push_str("[path] ");
        } else {
            out.push_str(word);
            out.push(' ');
        }
    }
    out.trim().to_string()
}

fn output_text(output: &Output) -> String {
    format!(
        "{}{}",
        String::from_utf8_lossy(&output.stderr),
        String::from_utf8_lossy(&output.stdout)
    )
}

fn command(bin: &str, args: &[String], extra_env: &[(&str, &str)]) -> Result<Output, String> {
    let mut cmd = Command::new(bin);
    cmd.args(args);
    for (key, value) in extra_env {
        cmd.env(key, value);
    }
    cmd.output().map_err(|_| format!("{bin} missing"))
}

fn check(output: &Output, label: &str) -> Result<(), String> {
    if output.status.success() {
        return Ok(());
    }
    Err(format!("{label} failed\n{}", sanitize(&output_text(output))))
}

fn llvm_tools() -> Result<(PathBuf, PathBuf), String> {
    let info = command("rustc", &["-vV".to_string()], &[])?;
    check(&info, "rustc")?;
    let text = String::from_utf8_lossy(&info.stdout);
    let host = text
        .lines()
        .find_map(|line| line.strip_prefix("host: "))
        .ok_or("llvm-cov missing")?
        .trim();
    let sysroot = command("rustc", &["--print".to_string(), "sysroot".to_string()], &[])?;
    check(&sysroot, "rustc")?;
    let root = String::from_utf8_lossy(&sysroot.stdout).trim().to_string();
    let bin = PathBuf::from(root).join("lib").join("rustlib").join(host).join("bin");
    let cov = bin.join("llvm-cov");
    let prof = bin.join("llvm-profdata");
    if !cov.is_file() || !prof.is_file() {
        return Err("llvm-cov missing".to_string());
    }
    Ok((cov, prof))
}

fn changed_lines(lib: &Path, range: &str) -> Result<HashSet<usize>, String> {
    let parent = lib.parent().unwrap_or_else(|| Path::new("."));
    let output = command(
        "git",
        &[
            "-C".to_string(),
            parent.display().to_string(),
            "diff".to_string(),
            "-U0".to_string(),
            range.to_string(),
            "--".to_string(),
            lib.file_name().and_then(|name| name.to_str()).unwrap_or("").to_string(),
        ],
        &[],
    )?;
    if !output.status.success() {
        return Err(sanitize(&output_text(&output)));
    }
    let mut lines = HashSet::new();
    let mut current: Option<usize> = None;
    for raw in String::from_utf8_lossy(&output.stdout).lines() {
        if let Some(rest) = raw.strip_prefix("@@") {
            current = None;
            if let Some(plus) = rest.split('+').nth(1) {
                let mut parts = plus.split([' ', ',']);
                let start: usize = parts.next().unwrap_or("0").parse().unwrap_or(0);
                let count: usize = parts.next().unwrap_or("1").trim_end_matches(|c: char| !c.is_ascii_digit()).parse().unwrap_or(1);
                if start > 0 && count > 0 {
                    current = Some(start);
                }
            }
            continue;
        }
        let Some(mut cursor) = current else { continue };
        if raw.starts_with("+++") || raw.starts_with("---") {
            continue;
        }
        if raw.starts_with('+') {
            lines.insert(cursor);
        }
        if raw.starts_with('+') || raw.starts_with(' ') {
            cursor += 1;
            current = Some(cursor);
        }
    }
    Ok(lines)
}

fn select<'a>(functions: &'a [Function], args: &Args) -> Result<Vec<&'a Function>, String> {
    if let Some(names) = &args.functions {
        let mut chosen = Vec::new();
        let mut missing = Vec::new();
        for name in names.split(',').map(str::trim).filter(|name| !name.is_empty()) {
            let exact: Vec<_> = functions.iter().filter(|func| func.name == name).collect();
            let found = if exact.is_empty() {
                functions.iter().filter(|func| func.name.ends_with(&format!(".{name}"))).collect()
            } else {
                exact
            };
            if found.is_empty() {
                missing.push(name.to_string());
            } else {
                chosen.extend(found);
            }
        }
        if !missing.is_empty() {
            return Err(format!("unknown functions: {}", missing.join(", ")));
        }
        return Ok(chosen);
    }
    if let Some(range) = &args.git_range {
        let lines = changed_lines(&args.lib, range)?;
        let hit: Vec<_> = functions
            .iter()
            .filter(|func| lines.iter().any(|line| func.start <= *line && *line <= func.end))
            .collect();
        let names: HashSet<_> = hit.iter().map(|func| func.name.as_str()).collect();
        let targets: Vec<_> = hit
            .into_iter()
            .filter(|func| !names.iter().any(|other| other.starts_with(&format!("{}.", func.name))))
            .collect();
        if targets.is_empty() {
            return Err(format!(
                "no touched functions in {}",
                args.lib.file_name().and_then(|name| name.to_str()).unwrap_or("lib")
            ));
        }
        return Ok(targets);
    }
    Ok(functions.iter().collect())
}

fn tracked_lines(value: &serde_json::Value, lib: &Path) -> Result<(HashSet<usize>, HashSet<usize>), String> {
    let files = value["data"][0]["files"]
        .as_array()
        .ok_or("lib not measured")?;
    let lib_name = lib.file_name().and_then(|name| name.to_str()).unwrap_or("");
    let lib_abs = fs::canonicalize(lib).unwrap_or_else(|_| lib.to_path_buf());
    let file = files.iter().find(|item| {
        let name = item["filename"].as_str().unwrap_or("");
        Path::new(name) == lib_abs || name.ends_with(lib_name)
    });
    let Some(file) = file else { return Err("lib not measured".to_string()) };
    let mut counts: HashMap<usize, u64> = HashMap::new();
    for segment in file["segments"].as_array().ok_or("lib not measured")? {
        let row = segment.as_array().ok_or("coverage missing")?;
        if row.get(3).and_then(|flag| flag.as_bool()) != Some(true) {
            continue;
        }
        let line = row.first().and_then(|item| item.as_u64()).ok_or("coverage missing")? as usize;
        let count = row.get(2).and_then(|item| item.as_u64()).unwrap_or(0);
        counts.entry(line).and_modify(|prev| *prev = (*prev).max(count)).or_insert(count);
    }
    let tracked = counts.keys().copied().collect();
    let covered = counts.into_iter().filter(|(_, count)| *count > 0).map(|(line, _)| line).collect();
    Ok((covered, tracked))
}

fn owner<'a>(functions: &[&'a Function], line: usize) -> Option<&'a Function> {
    functions
        .iter()
        .copied()
        .filter(|func| func.start <= line && line <= func.end)
        .min_by_key(|func| func.end.saturating_sub(func.start))
}

fn cover(lib: &Path, test: &Path) -> Result<(HashSet<usize>, HashSet<usize>), String> {
    let (cov, prof) = llvm_tools()?;
    let dir = std::env::temp_dir().join(format!("crap-rs-{}", std::process::id()));
    let _ = fs::remove_dir_all(&dir);
    fs::create_dir_all(&dir).map_err(|error| error.to_string())?;
    let cleanup = dir.clone();
    let result = (|| {
        let stem = lib
            .file_stem()
            .and_then(|name| name.to_str())
            .unwrap_or("lib")
            .replace('-', "_");
        let rlib = dir.join(format!("lib{stem}.rlib"));
        let prog = dir.join("prog");
        check(
            &command(
                "rustc",
                &[
                    "-C".to_string(),
                    "instrument-coverage".to_string(),
                    "--edition".to_string(),
                    "2021".to_string(),
                    "--crate-name".to_string(),
                    stem.clone(),
                    "--crate-type".to_string(),
                    "rlib".to_string(),
                    lib.display().to_string(),
                    "-o".to_string(),
                    rlib.display().to_string(),
                ],
                &[],
            )?,
            "rustc",
        )?;
        check(
            &command(
                "rustc",
                &[
                    "-C".to_string(),
                    "instrument-coverage".to_string(),
                    "--edition".to_string(),
                    "2021".to_string(),
                    "--test".to_string(),
                    test.display().to_string(),
                    "--extern".to_string(),
                    format!("{stem}={}", rlib.display()),
                    "-o".to_string(),
                    prog.display().to_string(),
                ],
                &[],
            )?,
            "coverage suite",
        )?;
        let profile = dir.join("prof_%p.profraw");
        check(
            &command(&prog.display().to_string(), &[], &[("LLVM_PROFILE_FILE", profile.to_str().unwrap_or(""))])?,
            "coverage suite",
        )?;
        let raws: Vec<String> = fs::read_dir(&dir)
            .map_err(|error| error.to_string())?
            .filter_map(|entry| entry.ok())
            .map(|entry| entry.path())
            .filter(|path| path.extension().and_then(|ext| ext.to_str()) == Some("profraw"))
            .map(|path| path.display().to_string())
            .collect();
        let data = dir.join("prof.data");
        let mut merge = vec!["merge".to_string(), "-sparse".to_string(), "-o".to_string(), data.display().to_string()];
        merge.extend(raws);
        check(&command(prof.to_str().unwrap_or(""), &merge, &[])?, "coverage")?;
        let exported = command(
            cov.to_str().unwrap_or(""),
            &[
                "export".to_string(),
                "-format=text".to_string(),
                format!("-instr-profile={}", data.display()),
                prog.display().to_string(),
            ],
            &[],
        )?;
        check(&exported, "coverage")?;
        let parsed: serde_json::Value = serde_json::from_slice(&exported.stdout).map_err(|_| "coverage missing".to_string())?;
        tracked_lines(&parsed, lib)
    })();
    let _ = fs::remove_dir_all(cleanup);
    result
}

fn print_score(args: &Args, targets: &[&Function], covered: &HashSet<usize>, tracked: &HashSet<usize>) -> i32 {
    let mut rows = Vec::new();
    for func in targets {
        let mut hit = 0;
        let mut total = 0;
        for line in tracked {
            if owner(targets, *line).is_some_and(|item| item.name == func.name && item.start == func.start) {
                total += 1;
                if covered.contains(line) {
                    hit += 1;
                }
            }
        }
        let cov = if total == 0 { 0.0 } else { hit as f64 / total as f64 };
        let comp = func.comp as f64;
        rows.push((func.name.clone(), func.comp, cov, crap(comp, cov)));
    }
    if rows.is_empty() || (tracked.is_empty() && rows.iter().all(|row| row.2 == 0.0)) {
        eprintln!("lib not measured");
        return 2;
    }
    rows.sort_by(|left, right| left.0.cmp(&right.0));
    let worst = rows.iter().max_by(|left, right| left.3.partial_cmp(&right.3).unwrap()).unwrap();
    let ok = worst.3 <= args.limit;
    if args.json {
        let payload = serde_json::json!({
            "ok": ok,
            "threshold": args.limit,
            "worst": {"name": worst.0, "crap": (worst.3 * 100.0).round() / 100.0},
            "functions": rows.iter().map(|row| serde_json::json!({
                "name": row.0,
                "comp": row.1,
                "cov": (row.2 * 10000.0).round() / 10000.0,
                "crap": (row.3 * 100.0).round() / 100.0,
            })).collect::<Vec<_>>(),
        });
        println!("{payload}");
        return if ok { 0 } else { 1 };
    }
    if args.functions.is_some() || args.git_range.is_some() {
        let names = rows.iter().map(|row| row.0.as_str()).collect::<Vec<_>>().join(",");
        let scope = if args.functions.is_some() { "functions" } else { "diff" };
        println!("scope={scope} functions={names}");
    } else {
        println!("scope=file");
    }
    for (name, comp, cov, score) in &rows {
        println!("{name}: comp={comp} cov={cov:.2} crap={score:.2}");
    }
    let limit = if args.limit.fract() == 0.0 {
        format!("{}", args.limit as i64)
    } else {
        args.limit.to_string()
    };
    println!("worst={} crap_max={:.2} threshold={limit}", worst.0, worst.3);
    if ok { 0 } else { 1 }
}

fn parse_args() -> Result<Args, String> {
    let mut limit = 6.0;
    let mut json = false;
    let mut functions = None;
    let mut git_range = None;
    let mut positionals = Vec::new();
    let mut iter = env::args().skip(1);
    while let Some(arg) = iter.next() {
        match arg.as_str() {
            "--json" => json = true,
            "--max" => {
                limit = iter.next().ok_or("invalid --max")?.parse().map_err(|_| "invalid --max")?;
            }
            "--functions" => functions = Some(iter.next().unwrap_or_default()),
            "--diff" => git_range = Some(iter.next().ok_or("invalid --diff")?),
            other if other.starts_with('-') => return Err(format!("unknown argument {other}")),
            other => positionals.push(other.to_string()),
        }
    }
    if positionals.len() != 2 {
        return Err("usage: crap-score-rust --max 6 lib test".to_string());
    }
    Ok(Args {
        limit,
        json,
        functions,
        git_range,
        lib: PathBuf::from(&positionals[0]),
        test: PathBuf::from(&positionals[1]),
    })
}

fn run() -> i32 {
    let args = match parse_args() {
        Ok(args) => args,
        Err(error) => {
            eprintln!("{error}");
            return 2;
        }
    };
    let source = match fs::read_to_string(&args.lib) {
        Ok(source) => source,
        Err(_) => {
            eprintln!("missing {}", args.lib.display());
            return 2;
        }
    };
    if fs::read(&args.test).is_err() {
        eprintln!("missing {}", args.test.display());
        return 2;
    }
    let functions = match functions_in(&source) {
        Ok(functions) => functions,
        Err(error) => {
            let name = args.lib.file_name().and_then(|item| item.to_str()).unwrap_or("lib");
            eprintln!("{}", if error == "no functions" { format!("no functions in {name}") } else { sanitize(&error) });
            return 2;
        }
    };
    let targets = match select(&functions, &args) {
        Ok(targets) => targets,
        Err(error) => {
            eprintln!("{}", sanitize(&error));
            return 2;
        }
    };
    let (covered, tracked) = match cover(&args.lib, &args.test) {
        Ok(lines) => lines,
        Err(error) => {
            eprintln!("{}", sanitize(&error));
            return 2;
        }
    };
    print_score(&args, &targets, &covered, &tracked)
}

fn main() {
    std::process::exit(run());
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn complexity_matches_the_branch_count() {
        let source = r#"
pub fn plain(x: i32) -> i32 { x }
pub fn gate(x: i32) -> i32 {
    if x > 0 && x < 3 { 1 } else { 0 }
}
pub fn choice(x: i32) -> i32 {
    match x {
        0 => 1,
        _ => 0,
    }
}
fn outer(x: i32) -> i32 {
    fn inner(y: i32) -> i32 { if y > 0 { 1 } else { 0 } }
    inner(x)
}
impl Box {
    fn method(&self, x: i32) -> i32 { if x > 0 { 1 } else { 0 } }
}
"#;
        let found = functions_in(source).unwrap();
        let comp = |name: &str| found.iter().find(|func| func.name == name).unwrap().comp;
        assert_eq!(comp("plain"), 1);
        assert_eq!(comp("gate"), 3);
        assert_eq!(comp("choice"), 3);
        assert_eq!(comp("outer"), 1);
        assert_eq!(comp("outer.inner"), 2);
        assert_eq!(comp("Box.method"), 2);
    }
}
