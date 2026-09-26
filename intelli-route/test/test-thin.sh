#!/usr/bin/env bash
# Composition plugin: references skills and pstack. Does not vendor either.
# Resolves every manifest path. A sibling symlink that 404s on GitHub fails here.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }

need() {
  local p="$1"
  [[ -f "$ROOT/$p" || -d "$ROOT/$p" ]] && ok "exists $p" || bad "missing $p"
}

need plugin.json
need LICENSE
need NOTICE.md
need README.md
need manifest.json
need AGENTS.md
need commands/intelli-route.md
need cursor/commands/intelli-route.md
need cursor/rules/intelli-route.mdc
need .grok/workflows/intelli-route.rhai
need bot/intelli-route.md
need agents/intelli-route.md

if [[ -d "$ROOT/skills" ]]; then bad "skills/ present (bodies must stay upstream)"; else ok "no skills/ copy"; fi
if [[ -d "$ROOT/skills/poteto-mode" || -d "$ROOT/poteto-mode" ]]; then bad "poteto-mode vendored"; else ok "no poteto-mode copy"; fi
if [[ -d "$ROOT/playbooks" ]]; then bad "playbooks/ present"; else ok "no playbooks/"; fi
if find "$ROOT" -type d -name 'principle-*' | grep -q .; then bad "principle-* vendored"; else ok "no principle copies"; fi
if find "$ROOT" -name 'SKILL.md' | grep -q .; then bad "SKILL.md vendored"; else ok "no SKILL.md"; fi

pj="$(cat "$ROOT/plugin.json")"
echo "$pj" | grep -q '"name": "intelli-route"' && ok "plugin.json name" || bad "plugin.json name"
echo "$pj" | grep -q 'Lauren Tan' && ok "plugin.json credits pstack" || bad "plugin.json missing credit"
echo "$pj" | grep -q 'at most four' && ok "plugin.json states the cap" || bad "plugin.json missing cap"

notice="$(cat "$ROOT/NOTICE.md")"
echo "$notice" | grep -q 'Lauren Tan' && ok "NOTICE: Lauren Tan" || bad "NOTICE missing Lauren Tan"
echo "$notice" | grep -q 'does not copy' && ok "NOTICE: does not copy" || bad "NOTICE should refuse copy"
echo "$notice" | grep -q 'github.com/p10ns11y/skills' && ok "NOTICE: skills repo" || bad "NOTICE missing skills repo"
echo "$notice" | grep -q 'eva-emptiness/skills/eva-emptiness/SKILL.md' && ok "NOTICE: eva path" || bad "NOTICE missing eva path"

rhai="$(cat "$ROOT/.grok/workflows/intelli-route.rhai")"
echo "$rhai" | grep -q 'agent(' && ok "workflow calls agent" || bad "workflow missing agent("
echo "$rhai" | grep -q 'complete(' && ok "workflow calls complete" || bad "workflow missing complete("
if echo "$rhai" | grep -q 'prompt('; then bad "workflow calls prompt("; else ok "workflow has no prompt("; fi

for surface in commands/intelli-route.md cursor/commands/intelli-route.md cursor/rules/intelli-route.mdc agents/intelli-route.md bot/intelli-route.md AGENTS.md README.md; do
  text="$(cat "$ROOT/$surface")"
  echo "$text" | grep -q 'money, legal, or health' && ok "HITL $surface" || bad "HITL missing in $surface"
  if echo "$text" | grep -qi 'open each'; then bad "open-each in $surface"; else ok "no open-each in $surface"; fi
done

readme="$(cat "$ROOT/README.md")"
if echo "$readme" | grep -q 'pstack-engineering.md'; then bad "README names a missing essay"; else ok "README has no missing essay"; fi
echo "$readme" | grep -q 'at most four' && ok "README states the cap" || bad "README missing cap"

if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 required"
else
  if python3 - "$ROOT" << 'PY'
import json, re, subprocess, sys
from pathlib import Path
from urllib.parse import urlparse

root = Path(sys.argv[1])
man = json.loads((root / "manifest.json").read_text())
plugin = json.loads((root / "plugin.json").read_text())
rhai = (root / ".grok/workflows/intelli-route.rhai").read_text()
errors = []

def bad(msg):
    errors.append(msg)

if plugin.get("version") != "0.3.0" or man.get("version") != "0.3.0":
    bad("version is not 0.3.0")
if man.get("max_loads") != 4:
    bad("max_loads is not 4")
emit = man.get("emit")
for field in ("situation", "route", "loads", "skips", "playbook", "hitl", "next"):
    if field not in emit:
        bad(f"emit missing {field}")
routes = man.get("routes") or {}
if set(routes) != {"light", "card", "empty"}:
    bad(f"routes {sorted(routes)}")

primary = man.get("primary") or []
by_route = {}
for row in primary:
    if row["id"] == "control-feeder":
        if "route" in row:
            bad("control-feeder must not own a route")
        continue
    by_route[row.get("route")] = row["id"]
if by_route != {"empty": "eva-emptiness", "card": "control-graph", "light": "pstack-map"}:
    bad(f"primary routes {by_route}")

loads = man.get("loads") or []
ids = [row["id"] for row in loads]
if len(ids) != len(set(ids)):
    bad("duplicate load ids")
fetchable = []
for row in loads:
    for key in ("id", "tier", "when", "repo", "ref", "path"):
        if not row.get(key):
            bad(f"{row.get('id')} missing {key}")
    if row["tier"] not in ("primary", "signal", "rule"):
        bad(f"{row['id']} bad tier")
    if row["tier"] != "rule":
        fetchable.append(row)
    if row["id"] == "eva-emptiness":
        if not row["repo"].endswith("/plugins") or row["path"] != "eva-emptiness/skills/eva-emptiness/SKILL.md":
            bad("eva-emptiness path is not the plugins skill")
    if row["repo"].endswith("/skills") and row["path"] == "eva-emptiness/SKILL.md":
        bad("skills-repo eva symlink is still a load path")

rule_ids = [row["id"] for row in loads if row["tier"] == "rule"]
if rule_ids != ["clt-dual-load"]:
    bad(f"rule tier {rule_ids}")

hitl = man.get("hitl_required") or []
for item in ("secrets", "production", "irreversible git", "CV promote", "unknown authorization", "money, legal, or health acts"):
    if item not in hitl:
        bad(f"hitl missing {item}")

m = re.search(r"let load_ids = \[(.*?)\];", rhai, re.S)
if not m:
    bad("workflow load_ids array missing")
    listed = []
else:
    listed = re.findall(r'"([^"]+)"', m.group(1))
want = [row["id"] for row in fetchable]
if listed != want:
    bad(f"load_ids {listed} != manifest {want}")
if "clt-dual-load" in listed:
    bad("rule id is in the fetch list")

um = re.search(r"let load_urls = \[(.*?)\];", rhai, re.S)
if not um:
    bad("workflow load_urls array missing")
    urls = []
else:
    urls = re.findall(r'"(https://[^"]+)"', um.group(1))
if len(urls) != len(listed):
    bad("load_urls length != load_ids")
for row, url in zip(fetchable, urls):
    owner_repo = urlparse(row["repo"]).path.strip("/")
    host = "raw.githubusercontent.com"
    expect = f"https://{host}/{owner_repo}/{row['ref']}/{row['path']}"
    if url != expect:
        bad(f"url for {row['id']}: {url} != {expect}")
if "rules/clt-dual-load.mdc" in rhai.split("let load_urls", 1)[-1].split("];", 1)[0]:
    bad("rule file is fetched")

if "prompt(" in rhai:
    bad("prompt( still present")

print("resolving", len(loads), "paths")
repo_root = root.parent
for row in loads:
    owner_repo = urlparse(row["repo"]).path.strip("/")
    local = repo_root / row["path"]
    if owner_repo == "p10ns11y/plugins" and local.is_file():
        continue
    api = f"repos/{owner_repo}/contents/{row['path']}?ref={row['ref']}"
    proc = subprocess.run(
        ["gh", "api", api, "-H", "Accept: application/vnd.github.object+json", "--jq", ".type"],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0 or proc.stdout.strip() not in ("file", "symlink"):
        err = (proc.stderr or proc.stdout).strip().splitlines()
        bad(f"missing {owner_repo}@{row['ref']}:{row['path']} {err[-1] if err else ''}")
    elif row["id"] == "eva-emptiness" and proc.stdout.strip() != "file":
        bad("eva-emptiness resolved to a symlink, not a file")

if errors:
    for msg in errors:
        print("FAIL", msg)
    sys.exit(1)
print("ok  manifest contract and live paths")
PY
  then
    ok "manifest contract"
  else
    bad "manifest contract"
  fi
fi

proof="$ROOT/../trust-stack/test/bend-critical.sh"
if [[ -f "$proof" ]]; then
  proof_out="$(bash "$proof" || true)"
  printf '%s\n' "$proof_out"
  if printf '%s\n' "$proof_out" | grep -q 'All terms check.'; then
    ok "Bend proved the trust laws"
  elif printf '%s\n' "$proof_out" | grep -q 'bend not installed'; then
    ok "Bend absent; trust laws not proved"
  else
    bad "Bend proof of the trust laws"
  fi
fi

echo "---"
if [[ "$fail" -ne 0 ]]; then
  echo "$fail failure(s)"
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
