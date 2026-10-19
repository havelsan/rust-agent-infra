#!/usr/bin/env bash
# migrate.sh - `migrate.sh` applies, verifies and rolls back migrations against a throwaway database
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: migrate.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "migrate.sh"
