---
name: progress-tracking
description: Report issue status by label and find stalled, blocked, and waiting issues. Use at the start of each Coordinator cycle and when asked where the project stands.
---

# progress-tracking

The Coordinator owns the project-level workflow, so it must know which issue is waiting for whom. The `to:*` and `status:*` labels give that picture.

## Procedure

1. Run these `list_issues` calls (`state=open`, `type=issues`, `per_page=20`). Read only number, title, labels, and update time. Do not open issues yet:
   - `labels=["to:Coordinator"]`: your queue. Add open issues with no `to:` label (new from the Human).
   - `labels=["to:Human"]`: waiting for the Human.
   - `labels=["status:blocked"]`.
   - `labels=["status:in-progress"]` with `before=<now minus 24 h, ISO 8601>`: stalled.
2. Write the report in at most 8 lines per section: counts, then the issue numbers that need action.
3. Act on each section:
   - **blocked**: find who must answer. If it is the Human, check that the issue is labeled `to:Human`. If a role agent is stuck, read its last comment and re-plan.
   - **Stalled**: an `in-progress` issue with no update usually means the agent stopped or the issue is unclear. Read it, then rewrite it, relabel it, or escalate (`human-escalation`).
   - **No `to:` label**: new from the Human. It is yours.
   - **done**: verify the result against the acceptance criteria, then close the issue and create follow-up issues (`issue-triage`).
4. Publish the report only when the Human wants a view without reading all issues: `wiki_write` (update or create) on the page `Project Status`.
5. Run it at the start of each Coordinator cycle and after each `done` issue.

## Why labels, not Gitea state

Gitea only has open and closed. The `status:*` labels carry the finer state, and `to:*` labels carry the owner. Keep exactly one of each on an open issue (`gitea-issues`).
