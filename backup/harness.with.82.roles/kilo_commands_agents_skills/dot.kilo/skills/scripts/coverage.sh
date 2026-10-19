#!/usr/bin/env bash
# coverage.sh
usage() { echo "Usage: coverage.sh [--dry-run] [--min PERCENT] [workspace-dir]  (needs cargo-llvm-cov)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
MIN=""; DIR="."
i=0
while [ $i -lt ${#ARGS[@]} ]; do
  if [ "${ARGS[$i]}" = "--min" ]; then i=$((i+1)); MIN="${ARGS[$i]}"; else DIR="${ARGS[$i]}"; fi
  i=$((i+1))
done
cd "$DIR" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
if [ -n "$MIN" ]; then
  run_step llvm-cov cargo llvm-cov --workspace --summary-only --fail-under-lines "$MIN"
else
  run_step llvm-cov cargo llvm-cov --workspace --summary-only
fi
finish coverage.sh
