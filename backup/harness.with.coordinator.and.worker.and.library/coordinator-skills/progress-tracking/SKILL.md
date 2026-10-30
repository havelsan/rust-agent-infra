---
name: progress-tracking
description: Report issue status by label and find stalled, blocked, and unassigned issues. Use at the start of each Coordinator cycle and when asked where the project stands.
---

# progress-tracking

The Coordinator owns the project-level workflow, so it must know which issue is waiting for whom. Status labels (`status:*`) and assignees give that picture.

## Procedure

1. Run the report:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/coordinator-skills/progress-tracking/scripts/status_report.py --stale-hours 24
```

2. Act on each section:
   - **blocked**: find who must answer. If it is the Human, check that the issue is assigned to the Human. If it is a Worker problem, read the Worker's comment and re-plan.
   - **Stalled**: a `todo` or `in-progress` issue with no update for a long time usually means the Worker stopped or the issue is unclear. Read it, then rewrite it, reassign it, or escalate (`human-escalation`).
   - **Open without assignee**: nobody will act on it. Assign it.
   - **done**: verify the result against the acceptance criteria, then close the issue and create follow-up issues (`issue-triage`).
3. Publish the report when the Human wants a view without reading all issues:

```bash
python3 .../status_report.py --wiki "Project Status"
```

4. Run the report at the start of each Coordinator cycle and after each `done` issue.

## Why labels, not Gitea state

Gitea only has open and closed. The `status:*` labels carry the finer state, and `gitea.py status` keeps exactly one of them on an issue.
