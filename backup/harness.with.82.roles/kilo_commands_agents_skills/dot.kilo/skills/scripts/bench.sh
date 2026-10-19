#!/usr/bin/env bash
# bench.sh
usage() { echo "Usage: bench.sh [--dry-run] [--baseline NAME] [workspace-dir]  (criterion benches)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
BASE=""; DIR="."
i=0
while [ $i -lt ${#ARGS[@]} ]; do
  if [ "${ARGS[$i]}" = "--baseline" ]; then i=$((i+1)); BASE="${ARGS[$i]}"; else DIR="${ARGS[$i]}"; fi
  i=$((i+1))
done
cd "$DIR" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
if [ -n "$BASE" ]; then
  run_step bench cargo bench --workspace -- --baseline "$BASE"
else
  run_step bench cargo bench --workspace
fi
finish bench.sh
