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

1. Create the issue (it skips creation if one is already open):

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/coordinator-skills/architecture-checkpoint/scripts/create_checkpoint.py [--focus "new persistence crate"]
```

2. The Worker loads the Architect role and runs `architecture-assessment`. The result goes to the wiki page `Architecture Status` and to the issue comment.
3. Read the result. For each finding with severity `high`, create a Developer issue (`issue-triage`). For a finding that needs a decision, use `human-escalation`.
4. Close the checkpoint issue and note the date in your status report.
