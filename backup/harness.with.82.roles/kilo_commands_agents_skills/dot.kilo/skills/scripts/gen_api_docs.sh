#!/usr/bin/env bash
# gen_api_docs.sh - `gen_api_docs.sh` builds OpenAPI and rustdoc references and fails on undocumented public items
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: gen_api_docs.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "gen_api_docs.sh"
