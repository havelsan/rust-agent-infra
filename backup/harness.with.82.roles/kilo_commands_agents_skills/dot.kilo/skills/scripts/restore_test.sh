#!/usr/bin/env bash
# restore_test.sh - `restore_test.sh` restores the latest backup into a scratch instance and runs integrity checks
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: restore_test.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "restore_test.sh"
