#!/usr/bin/env bash
# scaffold_harness.sh - `scaffold_harness.sh` generates a harness crate with fixture builders and mock traits
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: scaffold_harness.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "scaffold_harness.sh"
