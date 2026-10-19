#!/usr/bin/env bash
# fuzz_run.sh
usage() { echo "Usage: fuzz_run.sh [--dry-run] --target NAME [--seconds N]  (needs cargo-fuzz and nightly)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
TARGET=""; SECS=300
i=0
while [ $i -lt ${#ARGS[@]} ]; do
  case "${ARGS[$i]}" in
    --target) i=$((i+1)); TARGET="${ARGS[$i]}" ;;
    --seconds) i=$((i+1)); SECS="${ARGS[$i]}" ;;
  esac
  i=$((i+1))
done
[ -n "$TARGET" ] || { usage; exit 2; }
run_step fuzz cargo +nightly fuzz run "$TARGET" -- -max_total_time="$SECS"
finish fuzz_run.sh
