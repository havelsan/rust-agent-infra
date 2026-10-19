#!/usr/bin/env bash
# graphify_build.sh
usage() { echo "Usage: graphify_build.sh [--dry-run] [--force] [path]  (env GRAPHIFY_BUILD_CMD, default: graphify update {path})"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
PATHARG="."; FORCE=""
for a in "${ARGS[@]}"; do case "$a" in --force) FORCE="--force" ;; *) PATHARG="$a" ;; esac; done
CMD_T="${GRAPHIFY_BUILD_CMD:-graphify update {path}}"
CMD="${CMD_T//\{path\}/$PATHARG} $FORCE"
GRAPH="${GRAPHIFY_GRAPH:-graphify-out/graph.json}"
if [ "$DRY_RUN" = 1 ]; then add_step plan skipped "would run: $CMD"; finish graphify_build.sh; fi
if ! command -v graphify >/dev/null 2>&1; then
  FAILED=1; add_step graphify fail "graphify is not installed: uv tool install graphifyy  (or: pipx install graphifyy)"; finish graphify_build.sh
fi
if [ ! -f .graphifyignore ]; then
  printf 'target/\n.git/\nnode_modules/\ngraphify-out/\n.kilo/library/\n.kilo/memory/epics/\n' > .graphifyignore
  add_step ignore pass "created .graphifyignore (Rust target/ and kctx working files excluded)"
fi
run_step build bash -c "$CMD"
if [ "$FAILED" = 0 ]; then
  if [ -f "$GRAPH" ]; then
    stats=$(python3 - "$GRAPH" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    nodes = d.get("nodes", [])
    edges = d.get("edges", d.get("links", []))
    print(f"nodes={len(nodes)} edges={len(edges)}")
except Exception as e:
    print(f"unreadable graph: {e}")
PY
)
    add_step graph pass "$GRAPH $stats"
  else
    FAILED=1; add_step graph fail "build finished but $GRAPH was not created: set GRAPHIFY_BUILD_CMD, or run /graphify . once inside an IDE session"
  fi
fi
finish graphify_build.sh
