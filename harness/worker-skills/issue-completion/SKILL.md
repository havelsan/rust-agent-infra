---
name: issue-completion
description: Finish a Worker issue with the standard comment, status label, hand back to the Coordinator, and memory clear. Use when work is done or blocked.
---

# issue-completion

After the Worker finishes, `worker-reset` clears its context. Whatever is not in the issue comment, the wiki, or the repository is lost. Completing an issue properly is therefore part of the work, not paperwork.

## Procedure

1. Check the acceptance criteria in the issue. Do not report `done` when a criterion is not met. Report `blocked` and say which one.
2. Make sure results are saved: code committed, wiki pages written, long output in a file or page.
3. Finish the issue:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/worker-skills/issue-completion/scripts/complete_issue.py 12 \
  --role Developer --status done \
  --done "Implemented the SAC policy update with unit tests." \
  --result "cargo test: 14 passed." \
  --changed "src/policy.rs" --changed "tests/policy.rs" \
  --next "Reviewer: review the policy module."
```

The script posts the standard comment (see `issue-comment-protocol`), sets `status:done` or `status:blocked`, and assigns the issue to `$COORDINATOR_USER` so the Coordinator sees it. It does not close the issue. The Coordinator verifies the result and closes it. Add `--close` only when the Coordinator told you to.

4. For a blocked issue, use `--status blocked` and say what is missing and who can supply it. Workers do not contact the Human directly. The Coordinator escalates.
5. Next, run `worker-reset`.

## Quality bar for the comment

- A reader with no context can tell what changed and where.
- Numbers (tests passed, findings count) are real output, not estimates.
- The next step names a role or a person.
