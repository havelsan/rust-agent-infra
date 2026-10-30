---
name: issue-completion
description: Finish a role issue with the standard comment, status label, hand back to the Coordinator, and memory clear. Use when work is done or blocked.
---

# issue-completion

After an agent finishes, its context is cleared or dropped. Whatever is not in the issue comment, the wiki, or the repository is lost. Completing an issue properly is part of the work, not paperwork.

## Procedure

1. Check the acceptance criteria in the issue. Do not report `done` when a criterion is not met. Report `blocked` and say which one.
2. Make sure results are saved: code committed, wiki pages written, long output in a file or page.
3. Post the standard comment (template in `issue-comment-protocol`) with `issue_write` `add_comment`.
4. Hand back: `issue_write` `replace_labels` with `to:Coordinator` and `status:done` (or `status:blocked`). Keep the other labels. `issue-polling` and `gitea-assignment-handoff` explain the label rules.
5. On `done`, clear local memory: `mem.py clear <n>`.
6. Do not close the issue. The Coordinator verifies and closes. Close only when the Coordinator told you to (`issue_write` `update`, `state=closed`).
7. Blocked: say what is missing and who can supply it. Role agents do not contact the Human. The Coordinator escalates.
8. Next: an agent in its own session runs `worker-reset`. A subagent returns one line (issue number, status) and stops.

## Quality bar for the comment

- A reader with no context can tell what changed and where.
- Numbers (tests passed, findings count) are real output, not estimates.
- The next step names a role or a person.
