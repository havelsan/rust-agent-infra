#!/usr/bin/env bash
# graph.sh status|build|report [N]|ask "question" [budget]|path A B|explain NODE
# Code and document map built by graphify. Falls back to a capped grep when no graph exists.
set -uo pipefail
G="${GRAPH_JSON:-graphify-out/graph.json}"; REP="$(dirname "$G")/GRAPH_REPORT.md"
MAXC="${GRAPH_MAX_CHARS:-6000}"
have() { command -v "$1" >/dev/null 2>&1; }
cap() { head -c "$MAXC"; }
cmd="${1:-status}"; [ $# -gt 0 ] && shift

case "$cmd" in
  status)
    if [ -f "$G" ]; then
      echo "graph: $G ($(( ($(date +%s) - $(stat -c %Y "$G")) / 3600 )) h old)"
      [ -f "$(dirname "$G")/needs_update" ] && echo "STALE: code changed. Run: graph.sh build"
    else echo "no graph. Run: graph.sh build"; fi
    have graphify || echo "graphify CLI missing: uv tool install graphifyy" ;;
  build)
    have graphify || { echo "graphify CLI missing. Install: uv tool install graphifyy  (or pipx install graphifyy)" >&2; exit 1; }
    if graphify update . ; then echo "graph updated"
    else echo "first build may need the assistant skill: run '/graphify .' once, then use 'graph.sh build' for updates" >&2; exit 1; fi ;;
  report)
    [ -f "$REP" ] || { echo "no report. Run: graph.sh build" >&2; exit 1; }
    head -n "${1:-60}" "$REP" | cap ;;
  ask)
    q="${1:?usage: graph.sh ask \"question\" [budget]}"; budget="${2:-1500}"
    if have graphify && [ -f "$G" ]; then graphify query "$q" --budget "$budget" --graph "$G" 2>&1 | cap
    else
      echo "[no graph: fallback grep]"
      kw=$(printf '%s' "$q" | tr -cs 'A-Za-z0-9_' '\n' | awk 'length>3' | head -3 | paste -sd'|')
      [ -n "$kw" ] && grep -rnEi --include='*.rs' --include='*.md' --include='*.toml' "$kw" . 2>/dev/null | grep -v '/target/' | head -n 30 | cap
    fi ;;
  path)    have graphify && [ -f "$G" ] || { echo "no graph" >&2; exit 1; }; graphify path "${1:?from}" "${2:?to}" --graph "$G" 2>&1 | cap ;;
  explain) have graphify && [ -f "$G" ] || { echo "no graph" >&2; exit 1; }; graphify explain "${1:?node}" --graph "$G" 2>&1 | cap ;;
  *) echo "usage: graph.sh status|build|report [N]|ask \"q\" [budget]|path A B|explain NODE" >&2; exit 64 ;;
esac
