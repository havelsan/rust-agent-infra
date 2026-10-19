#!/usr/bin/env bash
# package_desktop.sh - `package_desktop.sh` produces deb, AppImage, MSI or dmg packages and verifies they launch
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: package_desktop.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "package_desktop.sh"
