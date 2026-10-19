#!/usr/bin/env bash
# hw_probe.sh - `hw_probe.sh` reports CPU features, cache sizes, NUMA topology and memory bandwidth
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: hw_probe.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "hw_probe.sh"
