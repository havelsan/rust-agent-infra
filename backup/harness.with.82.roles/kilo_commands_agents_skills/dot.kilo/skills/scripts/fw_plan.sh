#!/usr/bin/env bash
# fw_plan.sh - `fw_plan.sh` generates nftables rules or cloud security-group diffs in dry-run mode for review
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: fw_plan.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "fw_plan.sh"
