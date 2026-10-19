#!/usr/bin/env bash
# crate_graph.sh - draw the workspace crate dependency graph (Mermaid) from cargo metadata
usage() { echo "Usage: crate_graph.sh [--dry-run] [workspace-dir]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
if [ "$DRY_RUN" = 1 ]; then
  echo '{"script":"crate_graph.sh","status":"dry-run","detail":"would run: cargo metadata --format-version 1 --no-deps"}'
  exit 0
fi
if ! meta=$(cargo metadata --format-version 1 --no-deps 2>&1); then
  printf '{"script":"crate_graph.sh","status":"fail","detail":%s}\n' "$(json_str "$meta")"
  exit 1
fi
printf '%s' "$meta" | python3 -c '
import json, sys
m = json.load(sys.stdin)
names = {p["name"] for p in m["packages"]}
edges = sorted({(p["name"], d["name"]) for p in m["packages"] for d in p["dependencies"] if d["name"] in names})
lines = ["graph TD"] + [f"  {a} --> {b}" for a, b in edges]
print(json.dumps({"script": "crate_graph.sh", "status": "pass", "crates": sorted(names), "edges": len(edges), "mermaid": "\n".join(lines)}))
'
