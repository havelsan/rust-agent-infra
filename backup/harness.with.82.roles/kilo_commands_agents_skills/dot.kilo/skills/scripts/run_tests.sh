#!/usr/bin/env bash
# run_tests.sh
usage() { echo "Usage: run_tests.sh [--dry-run] [workspace-dir]  (needs cargo-nextest)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
run_step nextest cargo nextest run --workspace --no-fail-fast
finish run_tests.sh
