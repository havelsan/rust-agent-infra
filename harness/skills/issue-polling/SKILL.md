---
name: issue-polling
description: Find the next open issue labeled for this agent, resuming an interrupted one first. Use when an agent starts as its own session, resets, or has no task.
---

# issue-polling

An agent has no task list of its own. The open Gitea issues labeled `to:<You>` are the task list. When the Coordinator calls you as a subagent it gives the issue number. Then skip polling and use that issue.

## Procedure

1. `list_issues` with `state=open`, `type=issues`, `labels=["to:<You>"]`, `per_page=20`. Filter by this one label and read the other labels from each result. Do not rely on a multi-label filter.
2. Pick one issue:
   - An issue with `status:in-progress` first. It means an earlier session was interrupted. Read its last comments, then resume.
   - Otherwise the lowest-numbered issue with `status:todo` (or no status label).
   - Skip `status:blocked` and `status:done`.
   - The result has no order guarantee. When the page is full (20), read the next page before you choose.
3. Nothing to do: run `sleep 60` in the shell, then poll again. Do not invent work. A subagent returns `none` and stops.
4. Claim the issue before starting: `replace_labels` with `status:in-progress`, other labels unchanged.
5. Check `Role:` on body line 1. It must be your own role (see your agent file). Then work, then finish with `issue-completion`.

## Rules

- Work on one issue at a time. Finish or block it before you look at the next.
- Read the last comments, not only the body. The Human or Coordinator may have changed the task.
- No `Role:` line, or a different role: do not guess. Comment `[<You>] misrouted`, set `status:blocked` and `to:Coordinator`.
