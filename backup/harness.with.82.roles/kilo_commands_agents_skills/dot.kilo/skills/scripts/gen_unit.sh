#!/usr/bin/env bash
# gen_unit.sh - `gen_unit.sh` generates a hardened unit file and validates it with `systemd-analyze verify`
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: gen_unit.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "gen_unit.sh"
