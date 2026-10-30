#!/usr/bin/env bash
# Run the harness cleanup script, then remind the agent to run /reset and /reload.
# /reset and /reload are agent commands. A shell script cannot run them.
set -euo pipefail
: "${RUST_AGENT_INFRA_DIR:?RUST_AGENT_INFRA_DIR is not set}"
CLEAR="${CLEAR_WORKER_SH:-$RUST_AGENT_INFRA_DIR/harness/clear_worker.sh}"
if [ ! -x "$CLEAR" ]; then
  echo "error: $CLEAR not found or not executable" >&2
  exit 1
fi
"$CLEAR"
echo "clear_worker.sh finished."
echo "NEXT: run /reset, then /reload, then start issue-polling again."
