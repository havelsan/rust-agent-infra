#!/usr/bin/env bash
# ponytail_audit.sh
usage() { echo "Usage: ponytail_audit.sh [--dry-run] [workspace-dir]  (cargo-machete optional)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
if [ "$DRY_RUN" = 1 ]; then
  add_step plan skipped "cargo machete; cargo tree --duplicates; largest .rs files"
  finish ponytail_audit.sh
fi
if command -v cargo-machete >/dev/null 2>&1; then
  if out=$(cargo machete 2>&1); then add_step unused-deps pass "none found"; else FAILED=1; add_step unused-deps fail "$(printf '%s' "$out" | tail -n 20)"; fi
else
  add_step unused-deps skipped "install: cargo install cargo-machete"
fi
dups=$(cargo tree --duplicates 2>/dev/null | head -n 30)
if [ -n "$dups" ]; then add_step duplicate-versions warn "$(printf '%s' "$dups" | head -n 20)"; else add_step duplicate-versions pass "none"; fi
big=$(find . -name '*.rs' -not -path './target/*' -print0 | xargs -0 wc -l 2>/dev/null | grep -v ' total$' | sort -rn | head -n 5)
add_step largest-files info "$big"
finish ponytail_audit.sh
