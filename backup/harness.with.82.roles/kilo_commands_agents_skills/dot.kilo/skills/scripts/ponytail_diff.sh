#!/usr/bin/env bash
# ponytail_diff.sh
usage() { echo "Usage: ponytail_diff.sh [--dry-run] [--base REF]  (env PONYTAIL_MAX_ADDED_LINES=400, PONYTAIL_MAX_NEW_FILES=5)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
BASE=""
i=0
while [ $i -lt ${#ARGS[@]} ]; do
  case "${ARGS[$i]}" in --base) i=$((i+1)); BASE="${ARGS[$i]}" ;; esac
  i=$((i+1))
done
if [ -z "$BASE" ]; then
  for r in origin/main main origin/master master; do
    if git rev-parse --verify -q "$r" >/dev/null 2>&1; then BASE="$r"; break; fi
  done
fi
if [ -z "$BASE" ]; then FAILED=1; add_step base fail "no base ref found, pass --base <ref>"; finish ponytail_diff.sh; fi
if [ "$DRY_RUN" = 1 ]; then add_step plan skipped "would diff $BASE...HEAD"; finish ponytail_diff.sh; fi
MAXL="${PONYTAIL_MAX_ADDED_LINES:-400}"; MAXF="${PONYTAIL_MAX_NEW_FILES:-5}"
add_step diff info "$(git diff --shortstat "$BASE"...HEAD 2>&1)"
added=$(git diff --numstat "$BASE"...HEAD | awk '{a+=$1} END{print a+0}')
newfiles=$(git diff --name-status "$BASE"...HEAD | grep -c '^A' || true)
newdeps=$(git diff -U0 "$BASE"...HEAD -- '*Cargo.toml' | grep -E '^\+[A-Za-z0-9_-]+ *=' | head -n 20)
if [ "$added" -gt "$MAXL" ]; then FAILED=1; add_step added-lines fail "$added added lines (limit $MAXL): look for a smaller solution"; else add_step added-lines pass "$added"; fi
if [ "$newfiles" -gt "$MAXF" ]; then FAILED=1; add_step new-files fail "$newfiles new files (limit $MAXF)"; else add_step new-files pass "$newfiles"; fi
if [ -n "$newdeps" ]; then add_step new-dependencies review "$newdeps"; else add_step new-dependencies pass "none"; fi
finish ponytail_diff.sh
