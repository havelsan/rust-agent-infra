#!/usr/bin/env bash
# summarize_book.sh - summarize a PDF part by part into a markdown file (wrapper around kctx summarize)
usage() { echo "Usage: summarize_book.sh [--dry-run] <pdf> [--out FILE] [--force]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
[ ${#ARGS[@]} -ge 1 ] || { usage; exit 2; }
if [ "$DRY_RUN" = 1 ]; then
  add_step plan skipped "would run: kctx summarize ${ARGS[*]}"
  finish summarize_book.sh
fi
exec python3 "$KDIR/bin/kctx" summarize "${ARGS[@]}"
