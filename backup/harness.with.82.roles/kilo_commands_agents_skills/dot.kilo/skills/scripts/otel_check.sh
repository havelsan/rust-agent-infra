#!/usr/bin/env bash
# otel_check.sh - `otel_check.sh` verifies that spans, metrics and log fields are emitted and exported
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: otel_check.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "otel_check.sh"
