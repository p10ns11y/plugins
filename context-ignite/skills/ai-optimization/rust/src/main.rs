use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::Command;

struct PackedSource {
    relative_path: String,
    relevance: i32,
    compressed: String,
    token_estimate: usize,
}

fn main() {
    let arguments: Vec<String> = env::args().skip(1).collect();
    if arguments.first().map(String::as_str) != Some("analyze") {
        eprintln!("usage: context-sage analyze --project DIR --query TEXT [--budget N] [--lang LANG] [--output FILE]");
        std::process::exit(2);
    }
    let mut project_root = env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let mut query = String::new();
    let mut budget: usize = 45000;
    let mut language = String::new();
    let mut output_path = PathBuf::from("context-pack.md");
    let mut argument_index = 1;
    while argument_index < arguments.len() {
        let flag = arguments[argument_index].as_str();
        let value = arguments.get(argument_index + 1).cloned();
        match flag {
            "--project" => project_root = PathBuf::from(value.unwrap_or_default()),
            "--query" => query = value.unwrap_or_default(),
            "--budget" => budget = value.unwrap_or_default().parse().unwrap_or(45000),
            "--lang" => language = value.unwrap_or_default(),
            "--output" => output_path = PathBuf::from(value.unwrap_or_default()),
            _ => {
                eprintln!("unknown argument {flag}");
                std::process::exit(2);
            }
        }
        argument_index += 2;
    }
    if query.is_empty() {
        eprintln!("--query is required");
        std::process::exit(2);
    }
    let selected_language = if language.is_empty() {
        None
    } else {
        Some(normalize_language(&language))
    };
    let keywords = query_keywords(&query);
    let mut packed_sources = Vec::new();
    if language_wants_native(selected_language.as_deref()) {
        scan_native(&project_root, selected_language.as_deref(), &keywords, &mut packed_sources);
    }
    if language_wants_c_family(selected_language.as_deref()) {
        match scan_c_family(&project_root, &query, selected_language.as_deref()) {
            Ok(c_family_sources) => packed_sources.extend(c_family_sources),
            Err(scan_error) => {
                eprintln!("{scan_error}");
                std::process::exit(1);
            }
        }
    }
    for packed_source in &mut packed_sources {
        let mut boost = 0;
        let lowered_path = packed_source.relative_path.to_lowercase();
        for keyword in &keywords {
            if lowered_path.contains(keyword) {
                boost += 12;
            }
        }
        packed_source.relevance = (packed_source.relevance + boost).min(100);
    }
    packed_sources.sort_by(|left, right| right.relevance.cmp(&left.relevance));
    let pack = render_pack(&project_root, &keywords, budget, &packed_sources);
    if let Some(parent) = output_path.parent() {
        if !parent.as_os_str().is_empty() {
            let _ = fs::create_dir_all(parent);
        }
    }
    fs::write(&output_path, &pack).unwrap_or_else(|write_error| {
        eprintln!("could not write {}: {write_error}", output_path.display());
        std::process::exit(1);
    });
    let mut stdout = io::stdout().lock();
    let _ = writeln!(
        stdout,
        "scanned {} files; pack {} (~{} tokens)",
        packed_sources.len(),
        output_path.display(),
        pack.len() / 4
    );
}

fn normalize_language(language_name: &str) -> String {
    let token = language_name.trim().to_lowercase().replace("++", "pp");
    match token.as_str() {
        "c" => "c".to_string(),
        "cpp" | "cxx" | "cc" | "cplusplus" => "cpp".to_string(),
        "rs" | "rust" => "rust".to_string(),
        "py" | "python" => "python".to_string(),
        "ts" | "typescript" => "typescript".to_string(),
        "js" | "javascript" => "javascript".to_string(),
        _ => {
            eprintln!("unknown --lang {language_name}. Use one of: c, cpp, rust, python, typescript, javascript");
            std::process::exit(2);
        }
    }
}

fn query_keywords(query: &str) -> Vec<String> {
    query
        .split(|character: char| !character.is_ascii_alphanumeric() && character != '_')
        .filter(|word| word.len() > 2)
        .map(|word| word.to_lowercase())
        .collect()
}

fn language_wants_c_family(selected_language: Option<&str>) -> bool {
    matches!(selected_language, None | Some("c") | Some("cpp"))
}

fn language_wants_native(selected_language: Option<&str>) -> bool {
    !matches!(selected_language, Some("c") | Some("cpp"))
}

fn extension_language(path: &Path) -> Option<&'static str> {
    match path.extension().and_then(|extension| extension.to_str()) {
        Some("rs") => Some("rust"),
        Some("py") => Some("python"),
        Some("ts") | Some("tsx") => Some("typescript"),
        Some("js") | Some("jsx") => Some("javascript"),
        _ => None,
    }
}

fn language_matches(file_language: &str, selected_language: Option<&str>) -> bool {
    match selected_language {
        None => true,
        Some(language_name) => file_language == language_name,
    }
}

fn path_is_skipped(path_text: &str) -> bool {
    const FRAGMENTS: &[&str] = &[
        "node_modules",
        "dist",
        "/target/",
        "target/",
        "__pycache__",
        "/.git/",
        "cmake-build",
        "CMakeFiles",
        "/build/",
        "third_party",
        "vendor",
        "/venv/",
        "/env/",
    ];
    FRAGMENTS.iter().any(|fragment| path_text.contains(fragment))
}

fn score_source(path_text: &str, content: &str, keywords: &[String]) -> i32 {
    let lowered_path = path_text.to_lowercase();
    let lowered_content = content.to_lowercase();
    let mut score = 0;
    if ["core", "domain", "service", "model", "auth", "user", "api", "main", "src", "include"]
        .iter()
        .any(|signal| lowered_path.contains(signal))
    {
        score += 25;
    }
    if ["test", "spec", "__pycache__", "node_modules", "dist", "cmake-build", "cmakefiles"]
        .iter()
        .any(|signal| lowered_path.contains(signal))
    {
        score -= 60;
    }
    for keyword in keywords {
        if lowered_path.contains(keyword) {
            score += 15;
        }
        if lowered_content.contains(keyword) {
            score += 8;
        }
    }
    if content.len() > 15000 {
        score -= 10;
    } else if content.len() < 200 {
        score -= 5;
    }
    score.clamp(0, 100)
}

fn scan_native(project_root: &Path, selected_language: Option<&str>, keywords: &[String], packed_sources: &mut Vec<PackedSource>) {
    let mut discovered = Vec::new();
    walk_native(project_root, project_root, selected_language, keywords, &mut discovered);
    discovered.sort_by(|left, right| right.0.cmp(&left.0));
    discovered.truncate(80);
    for (relevance, relative_path, content, file_language) in discovered {
        let source_name = Path::new(&relative_path)
            .file_name()
            .and_then(|name| name.to_str())
            .unwrap_or(&relative_path);
        let compressed = match file_language {
            "rust" => compress_rust(source_name, &content),
            "python" => compress_python(source_name, &content),
            _ => compress_script(source_name, &content),
        };
        let token_estimate = compressed.len() / 4;
        packed_sources.push(PackedSource {
            relative_path,
            relevance,
            token_estimate,
            compressed,
        });
    }
}

fn walk_native(
    project_root: &Path,
    directory: &Path,
    selected_language: Option<&str>,
    keywords: &[String],
    discovered: &mut Vec<(i32, String, String, &'static str)>,
) {
    let directory_text = directory.to_string_lossy();
    if directory != project_root && path_is_skipped(&directory_text) {
        return;
    }
    let entries = match fs::read_dir(directory) {
        Ok(entries) => entries,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let child_path = entry.path();
        let child_text = child_path.to_string_lossy().to_string();
        if path_is_skipped(&child_text) {
            continue;
        }
        if child_path.is_dir() {
            walk_native(project_root, &child_path, selected_language, keywords, discovered);
            continue;
        }
        let Some(file_language) = extension_language(&child_path) else {
            continue;
        };
        if !language_matches(file_language, selected_language) {
            continue;
        }
        let Ok(content) = fs::read_to_string(&child_path) else {
            continue;
        };
        let relative_path = child_path
            .strip_prefix(project_root)
            .unwrap_or(&child_path)
            .to_string_lossy()
            .to_string();
        let relevance = score_source(&child_text, &content, keywords);
        discovered.push((relevance, relative_path, content, file_language));
    }
}

fn declarations(content: &str) -> Vec<(String, bool)> {
    let mut collected = Vec::new();
    let mut pending = String::new();
    let mut first_line_indented = false;
    for raw_line in content.lines() {
        let stripped = raw_line.trim();
        if pending.is_empty() {
            if stripped.is_empty()
                || stripped.starts_with('#')
                || stripped.starts_with("//")
                || stripped.starts_with("/*")
                || stripped.starts_with('*')
            {
                continue;
            }
            pending = stripped.to_string();
            first_line_indented = raw_line.len() > stripped.len();
        } else {
            pending.push(' ');
            pending.push_str(stripped);
        }
        let pending_length = pending.len();
        let last_character = pending.chars().last();
        if matches!(last_character, Some('{') | Some(';') | Some('}')) || pending_length > 400 {
            collected.push((pending.clone(), first_line_indented));
            pending.clear();
        }
    }
    collected
}

fn purpose_line(content: &str, fallback: &str) -> String {
    for raw_line in content.lines() {
        let stripped = raw_line.trim();
        if stripped.starts_with("//") || stripped.starts_with("/*") || stripped.starts_with('*') {
            let purpose = stripped.trim_matches(|character: char| character == '/' || character == '*' || character.is_whitespace());
            if !purpose.is_empty() {
                return purpose.chars().take(120).collect();
            }
        } else if !stripped.is_empty() && !stripped.starts_with('#') {
            return fallback.to_string();
        }
    }
    fallback.to_string()
}

fn surface_line(declaration: &str, drop_body: bool) -> String {
    let cut = if drop_body {
        declaration.split('{').next().unwrap_or(declaration)
    } else {
        declaration
    };
    cut.trim().chars().take(180).collect()
}

fn rust_item(declaration: &str) -> Option<(bool, String, String)> {
    let mut remainder = declaration.trim();
    let mut is_public = false;
    if let Some(after_pub) = remainder.strip_prefix("pub") {
        let after_space = after_pub.trim_start();
        if after_space.starts_with('(') {
            let close = after_space.find(')')?;
            remainder = after_space[close + 1..].trim_start();
            is_public = true;
        } else if after_pub.starts_with(|character: char| character.is_whitespace()) || after_pub.is_empty() {
            remainder = after_space;
            is_public = true;
        }
    }
    if let Some(after_unsafe) = remainder.strip_prefix("unsafe") {
        if after_unsafe.starts_with(|character: char| character.is_whitespace()) {
            remainder = after_unsafe.trim_start();
        }
    }
    if let Some(after_async) = remainder.strip_prefix("async") {
        if after_async.starts_with(|character: char| character.is_whitespace()) {
            remainder = after_async.trim_start();
        }
    }
    let (kind, after_kind) = ["fn", "struct", "enum", "trait", "type", "const", "mod"]
        .iter()
        .find_map(|kind| {
            remainder.strip_prefix(kind).and_then(|after_kind| {
                if after_kind.starts_with(|character: char| character.is_whitespace()) {
                    Some(((*kind).to_string(), after_kind.trim_start()))
                } else {
                    None
                }
            })
        })?;
    let item_name: String = after_kind
        .chars()
        .take_while(|character| character.is_ascii_alphanumeric() || *character == '_')
        .collect();
    if item_name.is_empty() {
        return None;
    }
    Some((is_public, kind, item_name))
}

fn compress_rust(source_name: &str, content: &str) -> String {
    let mut lines = vec![format!("# {source_name} — {}", purpose_line(content, "Rust module"))];
    let mut kept = 0usize;
    for (declaration, indented) in declarations(content) {
        if kept >= 12 {
            break;
        }
        if let Some((is_public, kind, _item_name)) = rust_item(&declaration) {
            let private_item = !is_public && matches!(kind.as_str(), "fn" | "const" | "mod" | "type");
            let trait_or_impl_method = kind == "fn" && indented;
            if private_item && !trait_or_impl_method {
                continue;
            }
            lines.push(surface_line(&declaration, kind == "fn"));
            kept += 1;
        } else if declaration.trim_start().starts_with("impl") {
            lines.push(surface_line(&declaration, true));
            kept += 1;
        }
    }
    lines.join("\n")
}

fn python_purpose(content: &str) -> String {
    let trimmed = content.trim_start();
    for quote in ["\"\"\"", "'''"] {
        if let Some(body) = trimmed.strip_prefix(quote) {
            let docstring = body.split(quote).next().unwrap_or(body);
            let first_line = docstring.lines().find(|line| !line.trim().is_empty()).unwrap_or("").trim();
            if !first_line.is_empty() {
                return first_line.chars().take(120).collect();
            }
        }
    }
    purpose_line(content, "Python module")
}

fn compress_python(source_name: &str, content: &str) -> String {
    let mut lines = vec![format!("# {source_name} — {}", python_purpose(content))];
    let mut kept = 0usize;
    for raw_line in content.lines() {
        if kept >= 12 {
            break;
        }
        let stripped = raw_line.trim();
        let signature = if let Some(class_name) = stripped.strip_prefix("class ") {
            format!("class {}", class_name.split(':').next().unwrap_or(class_name).trim())
        } else if let Some(function_name) = stripped.strip_prefix("def ").or_else(|| stripped.strip_prefix("async def ")) {
            let header = function_name.split(':').next().unwrap_or(function_name).trim();
            let prefix = if stripped.starts_with("async def") { "async def" } else { "def" };
            format!("{prefix} {header}")
        } else {
            continue;
        };
        let item_name = signature.split(|character: char| character == ' ' || character == '(').nth(1).unwrap_or("");
        if item_name.starts_with('_') && !item_name.starts_with("__") {
            continue;
        }
        lines.push(signature);
        kept += 1;
    }
    if content.contains("nn.Module") || content.contains("LightningModule") || content.contains("flax.linen") || content.contains("keras.Model") {
        lines.push("# ML MODEL DETECTED — architecture summarized".to_string());
    }
    lines.join("\n")
}

fn compress_script(source_name: &str, content: &str) -> String {
    let mut lines = vec![format!("# {source_name} — {}", purpose_line(content, "script module"))];
    let mut kept = 0usize;
    for raw_line in content.lines() {
        if kept >= 12 {
            break;
        }
        let stripped = raw_line.trim();
        let keep = stripped.starts_with("export ")
            || stripped.starts_with("function ")
            || stripped.starts_with("class ")
            || stripped.starts_with("interface ")
            || stripped.starts_with("type ");
        if !keep || stripped.ends_with(',') {
            continue;
        }
        lines.push(surface_line(stripped, stripped.contains('{')));
        kept += 1;
    }
    lines.join("\n")
}

fn c_scanner_path() -> Result<PathBuf, String> {
    if let Ok(explicit) = env::var("CONTEXT_SAGE_C") {
        let path = PathBuf::from(explicit);
        if path.is_file() {
            return Ok(path);
        }
        return Err(format!("CONTEXT_SAGE_C does not point at a binary: {}", path.display()));
    }
    let executable = env::current_exe().map_err(|error| error.to_string())?;
    let executable_dir = executable.parent().unwrap_or(Path::new("."));
    let candidates = [
        executable_dir.join("context-sage-c"),
        executable_dir.join("../../../c/context-sage-c"),
        executable_dir.join("../../../../c/context-sage-c"),
    ];
    for candidate in candidates {
        if candidate.is_file() {
            return Ok(candidate);
        }
    }
    Err("C scanner missing. From the skill directory run: make".to_string())
}

fn scan_c_family(project_root: &Path, query: &str, selected_language: Option<&str>) -> Result<Vec<PackedSource>, String> {
    let scanner = c_scanner_path()?;
    let language_argument = selected_language.unwrap_or("all");
    let output = Command::new(&scanner)
        .arg("--project")
        .arg(project_root)
        .arg("--query")
        .arg(query)
        .arg("--lang")
        .arg(language_argument)
        .output()
        .map_err(|error| format!("could not run {}: {error}", scanner.display()))?;
    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }
    let text = String::from_utf8_lossy(&output.stdout);
    let mut packed_sources = Vec::new();
    let mut relative_path = String::new();
    let mut relevance = 0;
    let mut purpose = String::new();
    let mut signatures = Vec::new();
    for record in text.lines() {
        if let Some(rest) = record.strip_prefix("FILE\t") {
            let mut fields = rest.splitn(3, '\t');
            relative_path = fields.next().unwrap_or("").to_string();
            relevance = fields.next().unwrap_or("0").parse().unwrap_or(0);
            purpose = fields.next().unwrap_or("").to_string();
            signatures.clear();
        } else if let Some(signature) = record.strip_prefix("SIG\t") {
            if signatures.len() < 12 {
                signatures.push(signature.to_string());
            }
        } else if record == "END" && !relative_path.is_empty() {
            let source_name = Path::new(&relative_path)
                .file_name()
                .and_then(|name| name.to_str())
                .unwrap_or(&relative_path);
            let mut compressed_lines = vec![format!("# {source_name} — {purpose}")];
            compressed_lines.extend(signatures.iter().cloned());
            let compressed = compressed_lines.join("\n");
            let token_estimate = compressed.len() / 4;
            packed_sources.push(PackedSource {
                relative_path: relative_path.clone(),
                relevance,
                token_estimate,
                compressed,
            });
            relative_path.clear();
            signatures.clear();
        }
    }
    Ok(packed_sources)
}

fn render_pack(project_root: &Path, keywords: &[String], budget: usize, packed_sources: &[PackedSource]) -> String {
    let root_name = project_root.file_name().and_then(|name| name.to_str()).unwrap_or("project");
    let top_path = packed_sources.first().map(|source| source.relative_path.as_str()).unwrap_or("N/A");
    let overview = format!(
        "# Context Sage Pack — {root_name}\nQuery: {}\nBudget: {budget} tokens | Model: unknown (adjust with --budget)\n\n## Project Overview\n{} files scanned. Top relevance: {top_path}\n\n",
        keywords.join(" "),
        packed_sources.len()
    );
    let mut used_tokens = overview.len() / 4;
    let mut selected = Vec::new();
    for packed_source in packed_sources {
        if used_tokens + packed_source.token_estimate > (budget as f64 * 0.85) as usize {
            break;
        }
        used_tokens += packed_source.token_estimate;
        selected.push(packed_source);
    }
    let mut parts = vec![overview];
    for packed_source in &selected {
        parts.push(format!(
            "\n## {} (relevance {}/100, ~{} tokens)\n{}",
            packed_source.relative_path, packed_source.relevance, packed_source.token_estimate, packed_source.compressed
        ));
    }
    if selected.len() < packed_sources.len() {
        parts.push(format!(
            "\n# ... +{} lower-relevance files omitted to stay under budget",
            packed_sources.len() - selected.len()
        ));
    }
    parts.join("\n")
}
