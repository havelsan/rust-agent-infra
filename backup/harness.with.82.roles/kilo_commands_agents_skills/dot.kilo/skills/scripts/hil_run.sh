#!/usr/bin/env bash
# hil_run.sh - `hil_run.sh` runs the test suite on the board or an emulator and returns a JUnit report
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: hil_run.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "hil_run.sh"
