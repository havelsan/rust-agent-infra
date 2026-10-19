#!/usr/bin/env bash
# debt_scan.sh - `debt_scan.sh` combines clippy, complexity metrics, duplicate detection and TODO scans into a ranked report
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: debt_scan.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "debt_scan.sh"
