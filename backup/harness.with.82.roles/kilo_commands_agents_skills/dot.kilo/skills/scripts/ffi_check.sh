#!/usr/bin/env bash
# ffi_check.sh - `ffi_check.sh` generates headers or bindings and checks ABI and signature drift between the two sides
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: ffi_check.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "ffi_check.sh"
