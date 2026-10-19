#!/usr/bin/env bash
# api_lint.sh - `api_lint.sh` lints OpenAPI and proto files and checks for breaking changes against the previous version
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: api_lint.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "api_lint.sh"
