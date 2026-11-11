---
name: issue-triage
description: Split a Human goal into small, ordered role issues with one role each and acceptance criteria. Use when the Coordinator gets a new goal, a Human answer, or a finished role issue.
---

# issue-triage

The Coordinator turns a goal into work one agent session can finish. A role agent starts with an empty context, so each issue must stand alone and fit one role.

## Procedure

1. Read the Human issue and its last comments (`gitea-issues`). Check the wiki for existing requirements and architecture pages.
2. If the goal is unclear or a critical decision is missing, use `human-escalation`. Do not guess.
3. Split the work into items that follow this default flow. Skip steps the project does not need.
   `Analyzer` (check requirements) -> `Researcher` (crates) -> `Architect` -> `Designer` (if there is a UI) -> `Developer` + `Tester` -> `Reviewer` -> `Qa`
4. Write each item with: a one-line goal, inputs (issue numbers, wiki pages, requirement IDs), acceptance criteria that can be checked, output, and the role. Use `role-selection` when the role is not obvious. Plan at most 8 items. Save the plan with `mem.py note` or `mem.py plan`.
5. Create the issues one by one with `issue_write` `method=create`:
   - `title`: short and specific.
   - `labels`: `["to:<Role>", "status:todo"]`.
   - `body`:

```
Role: Analyzer
Parent: #1

Goal: check #1 for ambiguity and contradiction.
Inputs: #1, wiki Requirements-Index.
Acceptance: every finding has a severity.
Output: wiki page Requirements Review, comment with counts.
```

6. Comment on the parent issue with the list of created issues. Set the parent to `status:in-progress` (`replace_labels`, owner stays `to:Coordinator`).
7. Dispatch: call the agent named in each new `to:` label (see your agent file).

## Sizing rule

One issue should take one agent session. If an item needs two roles (for example code and tests), make two issues.

## Order

Agents run one after another. Create a dependent issue only when the earlier issue is `status:done` and verified. Do not create issues "for later". A waiting issue labeled `to:Coordinator` lands in your own queue.

## Steps (split points)

Use with `step-protocol`. 1. Read goal and wiki. 2. Draft at most 8 items. 3. Create. 4. Comment on the parent. For a large goal, plan phases and triage only the next phase.
