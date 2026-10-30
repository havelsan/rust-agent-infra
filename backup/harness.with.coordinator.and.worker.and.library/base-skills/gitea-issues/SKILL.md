---
name: gitea-issues
description: Read, create, comment on, assign, label, and set status of project-01 Gitea issues with the agent's own token. Use for all issue communication - picking up work, reporting, handing off.
---

# gitea-issues

Gitea issues are the only message channel between Human, Coordinator, and Worker. Use the bundled CLI instead of hand-written HTTP calls: it already handles paging, auth, and label ids, so results are consistent between agents.

## Setup (already done by start_agents.sh)

The CLI reads these environment variables. `GITEA_ACCESS_TOKEN` comes from the agent's own `.kilo/kilo.jsonc` (`COORDINATOR1_PERSONAL_ACCESS_TOKEN` or `WORKER1_PERSONAL_ACCESS_TOKEN`), so every action is attributed to the right agent.

| Variable | Meaning |
| --- | --- |
| `GITEA_URL` | Base URL, e.g. `http://localhost:3000` |
| `GITEA_OWNER`, `GITEA_REPO` | Repository, normally `project-01` |
| `GITEA_ACCESS_TOKEN` | Token of the current agent |

Run `python3 scripts/gitea.py ensure-labels` once per repository. It creates the `status:*` and `role:*` labels.

## Commands

```bash
G="python3 $RUST_AGENT_INFRA_DIR/harness/base-skills/gitea-issues/scripts/gitea.py"
$G whoami                                   # login of the current agent
$G list --assignee <user> [--state open] [--label status:todo] [--json]
$G get <n> --brief                          # body + last 5 comments, compact (default choice)
$G get <n> --comments                       # all comments as JSON (large, rarely needed)
$G create --title "..." --body-file body.md --assignee <user> --label role:analyzer
$G comment <n> --body-file comment.md       # use '-' to read stdin
$G assign <n> <user> [<user>...]            # replaces assignees
$G status <n> todo|in-progress|blocked|done # swaps the status:* label only
$G state <n> open|closed
$G labels <n> --add X --remove Y
```

## Conventions

- **Status** lives in a `status:*` label (`todo`, `in-progress`, `blocked`, `done`) because Gitea only knows open/closed. Use `status` rather than editing labels by hand so only one status label exists at a time.
- **Role** for a Worker issue is written in the issue body on its own line: `Role: <Name>` (see `role-selection`). The `role:<name>` label is an optional mirror for filtering.
- Read the issue with `get --brief` (body and last 5 comments) before acting; use `--last N` for more. Earlier comments often hold Human decisions that change the task.
- Write comments with the `issue-comment-protocol` skill and hand off with `gitea-assignment-handoff`.
- Never close an issue the agent did not work on.
