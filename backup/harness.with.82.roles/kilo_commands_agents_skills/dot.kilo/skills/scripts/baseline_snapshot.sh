#!/usr/bin/env bash
# baseline_snapshot.sh - `baseline_snapshot.sh` records config and versions; `drift_diff.py` compares a snapshot against live state
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: baseline_snapshot.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "baseline_snapshot.sh"
