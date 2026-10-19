#!/usr/bin/env bash
# gen_bindings.sh - `gen_bindings.sh` generates Swift and Kotlin bindings and checks that the shared API compiles for both targets
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: gen_bindings.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "gen_bindings.sh"
