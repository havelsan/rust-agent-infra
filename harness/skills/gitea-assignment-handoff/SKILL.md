---
name: gitea-assignment-handoff
description: Rules for passing an issue between Human, Coordinator, and role agents with the right owner and status labels. Use when handing off, escalating, or returning work.
---

# gitea-assignment-handoff

All agents share one Gitea account, so the owner of an issue is its `to:<Agent>` label. The agent named by that label must act next. A wrong or missing handoff stops the whole team, so change the labels in the same step as the comment.

## Who hands off to whom

| From | To | When | Owner label | Status label |
| --- | --- | --- | --- | --- |
| Human | Coordinator | Starts the project or gives a task (no `to:` label also counts) | `to:Coordinator` | `status:todo` |
| Coordinator | Role agent | Work item ready; `Role:` line names the role | `to:<Role>` | `status:todo` |
| Coordinator | Human | Cannot decide, or the decision is critical | `to:Human` | `status:blocked` |
| Role agent | Coordinator | Work finished, or the agent cannot continue | `to:Coordinator` | `status:done` or `status:blocked` |
| Human | Coordinator | Human answered a question | `to:Coordinator` | `status:in-progress` |

Role agents never set `to:Human`. They return `blocked` work to the Coordinator, who decides whether the Human must answer. The Human answers with a comment that has no `[Agent]` header. When the Coordinator finds such a newest comment on a `to:Human` issue, it relabels the issue itself.

## Procedure

1. Post the comment first (`issue-comment-protocol`, `issue_write` `add_comment`). The comment explains the handoff.
2. Get the current labels (`issue_read get`) unless you just read them.
3. `issue_write` `replace_labels` with the full new set: swap the `to:` and `status:` entries, keep every other label.
4. Stop working on the issue. After a handoff the agent no longer owns it.

If a label is missing, the call fails. Ask the Coordinator to run the setup in `gitea-issues`. Do not invent a label name.
