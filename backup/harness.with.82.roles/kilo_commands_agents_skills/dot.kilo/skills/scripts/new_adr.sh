#!/usr/bin/env bash
# new_adr.sh - `new_adr.sh` creates a numbered ADR from a template, sets its status, and updates the ADR index
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: new_adr.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "new_adr.sh"
