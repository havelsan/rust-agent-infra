---
name: gitea-assignment-handoff
description: Rules and a script for passing an issue between Human, Coordinator, and Worker with the right status label. Use when reassigning, escalating, or returning work.
---

# gitea-assignment-handoff

The assignee of an issue is the agent that must act next. A wrong or missing handoff stops the whole team, so change the assignee in the same step as the comment.

## Who hands off to whom

| From | To | When | Status label |
| --- | --- | --- | --- |
| Human | Coordinator | Starts the project or gives a new task | `todo` |
| Coordinator | Worker | Work item is ready; role is named in the issue body | `todo` |
| Coordinator | Human | Cannot decide, or the decision is critical | `blocked` |
| Worker | Coordinator | Work finished, or Worker cannot continue | `done` or `blocked` |
| Human | Coordinator | Human answered a question | `todo` |

Workers never assign to Human directly. They return `blocked` work to the Coordinator, who decides whether the Human must answer. This keeps one agent responsible for the Human's attention.

## Procedure

1. Write the comment first (see `issue-comment-protocol`). The comment explains the handoff.
2. Run the script. It posts the comment, sets the status label, and assigns the issue.

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/base-skills/issue-comment-protocol/scripts/format_comment.py ... > /tmp/c.md
$RUST_AGENT_INFRA_DIR/harness/base-skills/gitea-assignment-handoff/scripts/handoff.sh <issue> <assignee-login> <status> /tmp/c.md
```

3. Stop working on the issue. After a handoff the agent no longer owns it.

## Logins

Read agent logins from the environment: `HUMAN_USER`, `COORDINATOR_USER`, `WORKER_USER`. If a variable is missing, ask the Coordinator (Worker) or the Human (Coordinator) in an issue comment. Do not guess a login.
