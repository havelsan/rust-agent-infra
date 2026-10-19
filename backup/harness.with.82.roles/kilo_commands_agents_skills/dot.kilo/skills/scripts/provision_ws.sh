#!/usr/bin/env bash
# provision_ws.sh - `provision_ws.sh` installs the Rust toolchain, tools and configuration and verifies versions
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: provision_ws.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "provision_ws.sh"
