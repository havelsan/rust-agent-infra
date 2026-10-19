#!/usr/bin/env bash
# sysaudit.sh - `sysaudit.sh` reports failed units, disk usage, users, permissions and open ports
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: sysaudit.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "sysaudit.sh"
