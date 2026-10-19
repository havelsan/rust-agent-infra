#!/usr/bin/env bash
# hardening_scan.sh - `hardening_scan.sh` checks OS and service settings against a CIS-style baseline and lists deviations
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: hardening_scan.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "hardening_scan.sh"
