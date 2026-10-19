#!/usr/bin/env bash
# auth_scaffold.sh - `auth_scaffold.sh` adds middleware templates and generates negative authorization tests
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: auth_scaffold.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "auth_scaffold.sh"
