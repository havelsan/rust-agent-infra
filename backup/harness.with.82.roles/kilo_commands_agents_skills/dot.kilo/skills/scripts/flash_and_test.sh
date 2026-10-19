#!/usr/bin/env bash
# flash_and_test.sh - `flash_and_test.sh` builds for the target, flashes with probe-rs, and collects defmt logs
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: flash_and_test.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "flash_and_test.sh"
