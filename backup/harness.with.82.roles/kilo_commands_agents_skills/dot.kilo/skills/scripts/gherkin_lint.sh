#!/usr/bin/env bash
# gherkin_lint.sh - `gherkin_lint.sh` lints feature files and checks that each criterion maps to a REQ ID
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: gherkin_lint.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "gherkin_lint.sh"
