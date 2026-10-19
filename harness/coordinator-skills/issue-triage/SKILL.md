---
name: issue-triage
description: Split a Human goal into small, ordered Worker issues with one role each and acceptance criteria. Use when the Coordinator gets a new goal, a Human answer, or a finished Worker issue.
---

# issue-triage

The Coordinator turns a goal into work a single Worker session can finish. A Worker starts with an empty context and loads one role, so each issue must stand alone and fit one role.

## Procedure

1. Read the Human issue and its comments (`gitea-issues`, `get --brief`). Check the wiki for existing requirements and architecture pages.
2. If the goal is unclear or a critical decision is missing, use `human-escalation`. Do not guess.
3. Split the work into items that follow this default flow. Skip steps the project does not need.
   `Analyzer` (check requirements) -> `Researcher` (crates) -> `Architect` -> `Designer` (if there is a UI) -> `Developer` + `Tester` -> `Reviewer` -> `Qa`
4. Write each item with: a one-line goal, inputs (issue numbers, wiki pages), acceptance criteria that can be checked, and the role. Use `role-selection` when the role is not obvious.
5. Save the plan as JSON and create the issues:

```bash
cat > /tmp/plan.json <<'JSON'
[
  {"title": "Analyze requirements of issue #1", "role": "Analyzer", "parent": 1,
   "body": "Goal: check #1 for ambiguity and contradiction.\nOutput: wiki page 'Requirements Review'.\nDone when: every finding has a severity."},
  {"title": "Find Rust crate for MQTT client", "role": "Researcher", "parent": 1,
   "body": "Goal: list crates for an MQTT client. Output: comment with a table."}
]
JSON
python3 $RUST_AGENT_INFRA_DIR/harness/coordinator-skills/issue-triage/scripts/create_work_items.py /tmp/plan.json
```

Use `--dry-run` first to see the issue bodies.

6. Comment on the parent issue with the list of created issues and set the parent to `status:in-progress`.

## Sizing rule

One issue should take one Worker session. If an item needs two roles (for example code and tests), make two issues. This also keeps the Worker's `/reset` after each issue from losing half-finished work.

## Order

Workers read issues continuously, so a dependency must be visible. Create dependent issues only when the earlier issue is `status:done`, or write `Depends on: #N` in the body and keep the issue assigned to yourself until then.

## Steps (split points)

Use with `step-protocol`. 1. Read goal and wiki. 2. Draft at most 8 items. 3. `--dry-run`. 4. Create. 5. Comment on the parent. For a large goal, plan phases and triage only the next phase.
