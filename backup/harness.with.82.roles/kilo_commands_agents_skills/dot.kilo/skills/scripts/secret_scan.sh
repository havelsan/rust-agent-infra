#!/usr/bin/env bash
# secret_scan.sh
usage() { echo "Usage: secret_scan.sh [--dry-run] [repo-dir]  (needs gitleaks)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter repo dir"}'; exit 2; }
run_step gitleaks gitleaks detect --no-banner --redact
finish secret_scan.sh
