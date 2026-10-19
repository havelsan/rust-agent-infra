#!/usr/bin/env bash
# loadtest.sh - `loadtest.sh` runs a load tool (oha, k6 or goose) with a profile and reports latency percentiles and errors
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: loadtest.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "loadtest.sh"
