#!/usr/bin/env bash
# miri_loom.sh
usage() { echo "Usage: miri_loom.sh [--dry-run] [workspace-dir]  (needs nightly + miri; loom tests behind cfg(loom))"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
run_step miri cargo +nightly miri test
run_step loom env RUSTFLAGS=--cfg=loom cargo test --release
finish miri_loom.sh
