#!/usr/bin/env bash
# vuln_scan.sh - `vuln_scan.sh` runs scoped scanners and outputs findings with severity and reproduction notes
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: vuln_scan.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "vuln_scan.sh"
