#!/usr/bin/env bash
# build_image.sh - `build_image.sh` builds a musl or distroless image, generates an SBOM, and reports image size and layers
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: build_image.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "build_image.sh"
