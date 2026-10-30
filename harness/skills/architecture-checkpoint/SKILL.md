---
name: architecture-checkpoint
description: Create a periodic Architect issue that checks architecture drift. Use after several Developer issues, before a release, or after structural changes.
---

# architecture-checkpoint

Architecture drifts quietly while Developer issues are closed one by one. A checkpoint gives the Architect role a regular chance to catch it while it is cheap to fix.

## When to create one

- After every three to five completed Developer issues.
- Before a `Qa` release issue.
- After any change to a layer boundary, a new crate, or a new external dependency.
- When a Reviewer reports a structural problem.

## Procedure

1. Check for an open one: `list_issues` with `state=open`, `labels=["to:Architect"]`. If a title starts with `Architecture checkpoint`, stop. One is already open.
2. Create the issue with `issue_write` `method=create`. Title: `Architecture checkpoint <date>` (`date +%F`). Labels: `["to:Architect", "status:todo"]`. Body:

```
Role: Architect

Goal: check the architectural status of the project and report drift.

Steps:
1. Run the `architecture-assessment` skill on the workspace.
2. Compare the result with the wiki pages `Architecture Overview` and the latest ADRs.
3. Write findings to the wiki page `Architecture Status` (use `architecture-wiki`).
4. Comment on this issue with: drift found, risks, recommended issues.

Done when: `Architecture Status` is updated and every finding has a severity.
```

Add a line `Extra focus: <area>` when the Coordinator wants a specific area checked.

3. Dispatch to the Architect. It runs `architecture-assessment`. The result goes to the wiki page `Architecture Status` and to the issue comment.
4. Read the result. For each finding with severity `high`, create a Developer issue (`issue-triage`). For a finding that needs a decision, use `human-escalation`.
5. Close the checkpoint issue and note the date in your status report.
