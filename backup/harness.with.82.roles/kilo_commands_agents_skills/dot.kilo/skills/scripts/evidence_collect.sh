#!/usr/bin/env bash
# evidence_collect.sh - `evidence_collect.sh` gathers CI logs, approvals and scan reports per control into an evidence folder
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: evidence_collect.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "evidence_collect.sh"
