#!/usr/bin/env bash
# graphify_query.sh - query the graphify graph with a token budget; fall back to a keyword search
usage() { echo 'Usage: graphify_query.sh [--dry-run] [--budget TOKENS] [--graph FILE] "<question>"'; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
BUDGET=600; GRAPH="${GRAPHIFY_GRAPH:-graphify-out/graph.json}"; Q=""
i=0
while [ $i -lt ${#ARGS[@]} ]; do
  case "${ARGS[$i]}" in
    --budget) i=$((i+1)); BUDGET="${ARGS[$i]}" ;;
    --graph) i=$((i+1)); GRAPH="${ARGS[$i]}" ;;
    *) Q="${ARGS[$i]}" ;;
  esac
  i=$((i+1))
done
[ -n "$Q" ] || { usage; exit 2; }
MAXB=$((BUDGET*4))
if [ "$DRY_RUN" = 1 ]; then
  echo '{"script":"graphify_query.sh","status":"dry-run","detail":"would run graphify query, or a keyword search when no graph exists"}'
  exit 0
fi
if [ -f "$GRAPH" ] && command -v graphify >/dev/null 2>&1; then
  if out=$(graphify query "$Q" --graph "$GRAPH" --budget "$BUDGET" 2>&1); then
    printf '%s' "${out:0:$MAXB}" | emit_text graphify_query.sh pass graph
    exit 0
  fi
fi
KW=$(printf '%s' "$Q" | tr -cs 'A-Za-z0-9_' '\n' | awk 'length>3' | sort -u | head -n 3 | paste -sd'|' -)
out=""
if [ -n "$KW" ]; then
  if rtk_on; then
    out=$(rtk grep "$KW" . 2>&1 | head -n 40)
  else
    out=$(grep -rInE --include='*.rs' --include='*.toml' --include='*.md' -m 3 "$KW" . 2>/dev/null | grep -v '/target/' | head -n 40)
  fi
fi
printf '%s' "${out:0:$MAXB}" | emit_text graphify_query.sh pass grep-fallback
