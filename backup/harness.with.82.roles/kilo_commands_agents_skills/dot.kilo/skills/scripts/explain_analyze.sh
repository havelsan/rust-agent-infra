#!/usr/bin/env bash
# explain_analyze.sh - `explain_analyze.sh` runs EXPLAIN ANALYZE on given queries and flags full scans and missing indexes
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: explain_analyze.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "explain_analyze.sh"
