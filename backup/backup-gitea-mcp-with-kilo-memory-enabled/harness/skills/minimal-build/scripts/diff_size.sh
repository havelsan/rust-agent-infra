#!/usr/bin/env bash
# diff_size.sh [BASE]   Show how big the current change is. Warn when a step is too big.
# Env: STEP_MAX_ADDED (default 150) lines added per step.
set -uo pipefail
base="${1:-HEAD}"; max="${STEP_MAX_ADDED:-150}"
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 1; }
RT="${RUST_AGENT_INFRA_DIR:-}/harness/base-skills/lean-shell/scripts/rt.sh"; [ -x "$RT" ] || RT=""
$RT git diff --stat "$base" | tail -n 12
read -r added removed < <(git diff --numstat "$base" | awk '{a+=$1; r+=$2} END {print a+0, r+0}')
untracked=$(git ls-files --others --exclude-standard | grep -c '\.rs$' || true)
echo "added=$added removed=$removed new_rs_files=$untracked limit=$max"
if [ "$added" -gt "$max" ]; then
  echo "BIG STEP: $added lines added. Split the step (mem.py split), or remove code that no requirement asks for."
  exit 2
fi
echo "OK"
