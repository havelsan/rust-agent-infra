#!/usr/bin/env bash
# deps_audit.sh
usage() { echo "Usage: deps_audit.sh [--dry-run] [workspace-dir]  (needs cargo-audit, cargo-deny)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
run_step audit cargo audit
run_step deny cargo deny check
run_step sbom cargo cyclonedx --format json
finish deps_audit.sh
