#!/usr/bin/env bash
# demo_env.sh - `demo_env.sh` provisions a disposable demo environment with sample data and resets it after use
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: demo_env.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "demo_env.sh"
