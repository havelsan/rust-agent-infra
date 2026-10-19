#!/usr/bin/env bash
# release.sh - `release.sh` bumps SemVer, tags, builds and signs artifacts, and attaches them to the Gitea release
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: release.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "release.sh"
