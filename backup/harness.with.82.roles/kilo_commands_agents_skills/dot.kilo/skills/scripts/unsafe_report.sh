#!/usr/bin/env bash
# unsafe_report.sh
usage() { echo "Usage: unsafe_report.sh [--dry-run] [workspace-dir]  (needs cargo-geiger)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
run_step geiger cargo geiger
if [ "$DRY_RUN" = 1 ]; then
  add_step safety-comments skipped "dry-run"
else
  missing=$(find . -name '*.rs' -not -path './target/*' -print0 | xargs -0 awk 'FNR==1{prev=""} /unsafe[ ]*\{/ && prev !~ /SAFETY:/ {print FILENAME":"FNR} {prev=$0}')
  if [ -n "$missing" ]; then FAILED=1; add_step safety-comments fail "unsafe blocks without a preceding // SAFETY: comment: $(printf '%s' "$missing" | head -n 20 | tr '\n' ' ')"; else add_step safety-comments pass ""; fi
fi
finish unsafe_report.sh
