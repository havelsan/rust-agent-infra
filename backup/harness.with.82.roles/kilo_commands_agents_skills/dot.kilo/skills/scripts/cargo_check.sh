#!/usr/bin/env bash
# cargo_check.sh
usage() { echo "Usage: cargo_check.sh [--dry-run] [workspace-dir]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
run_step fmt cargo fmt --all -- --check
run_step clippy cargo clippy --workspace --all-targets -- -D warnings
run_step build cargo build --workspace
run_step test cargo test --workspace
finish cargo_check.sh
