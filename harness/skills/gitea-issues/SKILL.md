---
name: gitea-issues
description: Read, create, comment on, label, route, and close project-01 Gitea issues with the gitea-mcp tools. Use for all issue communication - picking up work, reporting, handing off.
---

# gitea-issues

Gitea issues are the only message channel between the Human and the agents. All agents share one Gitea account, so nobody is assigned. Routing lives in labels and in the comment header (see `AGENTS.md`).

## Tools (gitea-mcp)

Kilo shows them as `gitea_<tool>` when the MCP server is named `gitea`. Every call needs `owner` and `repo`. Read them once with `echo $GITEA_OWNER $GITEA_REPO` and save them with `mem.py note`.

| Need | Tool | Key arguments |
| --- | --- | --- |
| List | `list_issues` | `state=open`, `type=issues`, `labels=["to:Developer"]`, `per_page=20` |
| Read | `issue_read` `method=get` | `issue_number` |
| Read comments | `issue_read` `method=get_comments` | `issue_number`, `per_page=5`, `page` |
| Create | `issue_write` `method=create` | `title`, `body`, `labels=[names]` |
| Comment | `issue_write` `method=add_comment` | `issue_number`, `body` |
| Set labels | `issue_write` `method=replace_labels` | `issue_number`, `labels=[full list]` |
| Close, reopen | `issue_write` `method=update` | `issue_number`, `state=closed` or `open` |

`list_issues` defaults to `state=all` and gives no order guarantee. Pass `state=open` and take the lowest issue number. Tool arguments are authoritative: if a call fails, read the tool schema.

## Reading an issue (small output)

1. `issue_read get`: body, labels, comment count `C`.
2. Last 5 comments: `get_comments` with `per_page=5`, `page=ceil(C/5)`. If that page has fewer than 3 comments and `C > 5`, also read `page-1`. Earlier comments often hold Human decisions, so read more pages when the task looks changed.

## Labels

| Label | Meaning |
| --- | --- |
| `to:<Agent>` | Exactly one per open issue. The agent that acts next. `Coordinator`, `Analyzer`, `Researcher`, `Architect`, `Designer`, `Developer`, `Tester`, `Reviewer`, `Qa`, `Human` |
| `status:todo`, `status:in-progress`, `status:blocked`, `status:done` | Exactly one per open issue. Gitea only knows open and closed |

- `replace_labels` replaces ALL labels. Take the current labels from `issue_read get`, swap the `to:` and `status:` entries, keep the rest, and send the full list. Change owner and status in one call.
- `add_labels` and `replace_labels` fail on a label that does not exist. Create labels first (setup below).
- The role of a work item is the first body line `Role: <Name>`. The Coordinator writes it. Nobody else edits it.

## Setup (once per repository)

The Coordinator checks with `label_read` (method `list`). For each missing label it calls `label_write` (method `create`, `name`, `color` as `#RRGGBB`):

| Labels | Color |
| --- | --- |
| `status:todo` | `#c5def5` |
| `status:in-progress` | `#fbca04` |
| `status:blocked` | `#d93f0b` |
| `status:done` | `#0e8a16` |
| `to:Coordinator`, `to:Analyzer`, `to:Researcher`, `to:Architect`, `to:Designer`, `to:Developer`, `to:Tester`, `to:Reviewer`, `to:Qa` | `#5319e7` |
| `to:Human` | `#b60205` |

## Rules

- Write comments with `issue-comment-protocol`. Hand off with `gitea-assignment-handoff`.
- Touch only issues that carry your own `to:` label.
- Never close an issue you did not work on. The Coordinator closes.
- Never put tokens or passwords in an issue.
