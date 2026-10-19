---
name: rust-code-review
description: Review Rust changes with automatic checks and a checklist and report findings by severity. Use for Reviewer tasks.
---

# rust-code-review

A review catches what the author cannot see. Automatic checks remove the easy findings, so the reviewer's time goes to design and meaning.

## Procedure

1. Read the issue, the linked requirements, and the diff. Know what the change should do before you read how it does it.
2. Run the automatic checks. They write `review-report.md`:

```bash
$RUST_AGENT_INFRA_DIR/harness/library/skills/rust-code-review/scripts/review_gate.sh <project-dir>
```

Any FAIL is a `blocker` until fixed. Tools that are not installed show as SKIPPED. Say so in the review.
3. Read the code with `references/review-checklist.md`. Ask of each hunk which requirement needs it (`minimal-build`). Check the layers, error handling, tests, and the principles (`principles-check`, `nasa-rules-solid`).
4. Write findings as `severity | file:line | problem | suggested fix`. Use `blocker`, `major`, `minor`. Quote the line when it is not obvious.
5. Decide: **approved** (no blocker, no major) or **changes requested**. Comment on the issue (`issue-comment-protocol`) with the decision, counts, and the top findings. Put long reports in the wiki.
6. Return the issue to the Coordinator. Do not fix the code yourself. A reviewer who edits the code reviews their own work.

## Rules

- Review the change, not the author.
- Give a reason and a fix for each finding.
- Do not approve what you did not check. Say which parts you did not review.
- Praise is allowed when a solution is good. It tells the Developer what to repeat.

## Steps (split points)

Use with `step-protocol`. 1. Automatic gate. 2. Read the diff per file or per 200 changed lines, one step each, `note` findings as you go. 3. Decision comment.
