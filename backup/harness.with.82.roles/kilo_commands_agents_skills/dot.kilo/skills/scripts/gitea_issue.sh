#!/usr/bin/env bash
# gitea_issue.sh - wrapper over the Gitea REST API (create, comment, label, assign, close, get, list)
# Usage: gitea_issue.sh [--dry-run] <create|comment|label|assign|close|get|list> [options]
# Env: GITEA_URL, GITEA_TOKEN, GITEA_REPO (owner/repo)
exec python3 "$(dirname "$0")/_gitea.py" "$@"
