#!/usr/bin/env bash
# standards_check.sh
usage() { echo "Usage: standards_check.sh [--dry-run] [--base REF] [--domain PATTERN]  (default domain pattern: domain)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
BASE=""; DOM="domain"
i=0
while [ $i -lt ${#ARGS[@]} ]; do
  case "${ARGS[$i]}" in
    --base) i=$((i+1)); BASE="${ARGS[$i]}" ;;
    --domain) i=$((i+1)); DOM="${ARGS[$i]}" ;;
  esac
  i=$((i+1))
done
if [ -z "$BASE" ]; then
  for r in origin/main main origin/master master; do
    if git rev-parse --verify -q "$r" >/dev/null 2>&1; then BASE="$r"; break; fi
  done
fi
if [ -z "$BASE" ]; then FAILED=1; add_step base fail "no base ref found, pass --base <ref>"; finish standards_check.sh; fi
if [ "$DRY_RUN" = 1 ]; then add_step plan skipped "would check $BASE...HEAD for tests, domain purity and unwrap in domain code"; finish standards_check.sh; fi
changed=$(git diff --name-only "$BASE"...HEAD -- '*.rs')
if [ -z "$changed" ]; then add_step changes pass "no Rust files changed"; finish standards_check.sh; fi
test_files=$(printf '%s\n' "$changed" | grep -E '(^|/)tests?/|_test\.rs$' || true)
src_files=$(printf '%s\n' "$changed" | grep -vE '(^|/)tests?/|_test\.rs$' || true)
new_tests=$(git diff -U0 "$BASE"...HEAD -- '*.rs' | grep -cE '^\+[[:space:]]*#\[(tokio::)?test' || true)
if [ -n "$src_files" ] && [ -z "$test_files" ] && [ "$new_tests" -eq 0 ]; then
  FAILED=1; add_step tdd fail "source files changed but no test was added or changed (heuristic: write the failing test first)"
else
  add_step tdd pass "$new_tests new #[test] attributes, $(printf '%s' "$test_files" | grep -c . || true) test files touched"
fi
dom_files=$(printf '%s\n' "$src_files" | grep -E "$DOM" || true)
if [ -n "$dom_files" ]; then
  io=$(printf '%s\n' "$dom_files" | xargs -d '\n' grep -nE '^use (std::(fs|net|process)|tokio|sqlx|diesel|reqwest|axum|actix|hyper)' 2>/dev/null | head -n 10)
  if [ -n "$io" ]; then FAILED=1; add_step domain-purity fail "IO or framework imports in domain code: $io"; else add_step domain-purity pass "domain files are IO-free"; fi
  uw=$(printf '%s\n' "$dom_files" | xargs -d '\n' grep -nE '\.unwrap\(\)|\.expect\(' 2>/dev/null | head -n 10)
  if [ -n "$uw" ]; then add_step unwrap-in-domain warn "$uw"; else add_step unwrap-in-domain pass "none"; fi
else
  add_step domain-purity skipped "no changed files match the domain pattern ($DOM)"
fi
finish standards_check.sh
