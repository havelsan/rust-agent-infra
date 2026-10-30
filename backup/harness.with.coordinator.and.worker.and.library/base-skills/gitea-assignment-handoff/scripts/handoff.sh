#!/usr/bin/env bash
# handoff.sh <issue> <assignee> <status> <comment-file|->
# Posts the comment, sets the status label, and assigns the issue in one step.
set -euo pipefail
if [ $# -ne 4 ]; then
  echo "usage: $0 <issue> <assignee> <todo|in-progress|blocked|done> <comment-file|->" >&2
  exit 64
fi
: "${RUST_AGENT_INFRA_DIR:?RUST_AGENT_INFRA_DIR is not set}"
GITEA_CLI="${GITEA_CLI:-$RUST_AGENT_INFRA_DIR/harness/base-skills/gitea-issues/scripts/gitea.py}"
issue="$1"; assignee="$2"; status="$3"; comment="$4"

python3 "$GITEA_CLI" comment "$issue" --body-file "$comment"
python3 "$GITEA_CLI" status "$issue" "$status"
python3 "$GITEA_CLI" assign "$issue" "$assignee"
