#!/usr/bin/env bash
# scaffold_service.sh - `scaffold_service.sh` generates a service skeleton with config, tracing and health routes
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: scaffold_service.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "scaffold_service.sh"
