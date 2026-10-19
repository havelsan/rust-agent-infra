#!/usr/bin/env bash
# compress_memory.sh - shrink markdown memory files in caveman style via kctx compress
usage() { echo "Usage: compress_memory.sh [--dry-run] [--mode lite|full|ultra] <file-or-dir>"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
EXTRA=()
[ "$DRY_RUN" = 1 ] && EXTRA=(--dry-run)
[ ${#ARGS[@]} -ge 1 ] || { usage; exit 2; }
exec python3 "$KDIR/bin/kctx" compress "${EXTRA[@]}" "${ARGS[@]}"
