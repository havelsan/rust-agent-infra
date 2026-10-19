#!/usr/bin/env bash
# tool_scaffold.sh - `tool_scaffold.sh` generates a Rust CLI or service template wired into CI and the docs
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: tool_scaffold.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "tool_scaffold.sh"
