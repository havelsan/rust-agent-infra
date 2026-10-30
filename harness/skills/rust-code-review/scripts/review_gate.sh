#!/usr/bin/env bash
# review_gate.sh [PROJECT_DIR] [REPORT_FILE]
# Run automatic checks for a code review and write a markdown report.
set -uo pipefail
dir="${1:-.}"; report="${2:-review-report.md}"
cd "$dir" || exit 1
RT="${RUST_AGENT_INFRA_DIR:-}/harness/base-skills/lean-shell/scripts/rt.sh"; [ -x "$RT" ] || RT=""
command -v cargo >/dev/null || { echo "error: cargo not found" >&2; exit 127; }
scan="${RUST_AGENT_INFRA_DIR:-}/harness/library/skills/principles-check/scripts/rust_rules_scan.py"

fails=0
{
  echo "# Automatic review checks"
  echo
  echo "| Check | Result |"
  echo "| --- | --- |"
} > "$report"
detail=""
run() { # name, command...
  local name="$1"; shift
  if out=$("$@" 2>&1); then echo "| $name | PASS |" >> "$report"
  else echo "| $name | FAIL |" >> "$report"; fails=$((fails+1))
       detail+=$'\n'"## $name"$'\n```\n'"$(printf '%s\n' "$out" | head -40)"$'\n```\n'; fi
}
skip() { echo "| $1 | SKIPPED ($2) |" >> "$report"; }

run "cargo fmt --check" cargo fmt --all -- --check
run "cargo clippy -D warnings" $RT cargo clippy --workspace --all-targets -- -D warnings
run "cargo test" $RT cargo test --workspace
if cargo audit --version >/dev/null 2>&1; then run "cargo audit" cargo audit; else skip "cargo audit" "not installed"; fi
if cargo deny --version >/dev/null 2>&1; then run "cargo deny check" cargo deny check; else skip "cargo deny" "not installed"; fi
if [ -f "$scan" ]; then
  out=$(python3 "$scan" . 2>&1); n=$(printf '%s\n' "$out" | grep -cE ': N[0-9]+ ' || true)
  echo "| rules scan (heuristic) | $n finding(s), see below |" >> "$report"
  detail+=$'\n'"## Rules scan"$'\n```\n'"$(printf '%s\n' "$out" | head -60)"$'\n```\n'
else skip "rules scan" "scanner not found"; fi
printf '%s' "$detail" >> "$report"
cat "$report"
exit $fails
