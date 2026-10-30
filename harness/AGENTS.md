# AGENTS.md - Team workflow

Shared by all agents in `.kilo/agents`. Each agent file holds its own role rules. This file holds the flow between them.
Only channel: Gitea issues + wiki of `project-01`. One shared Gitea account: nobody is assigned. Routing lives in labels and issue text.
Gitea access: gitea-mcp tools only (`list_issues`, `issue_read`, `issue_write`, `wiki_read`, `wiki_write`, `label_read`, `label_write`). Details in the `gitea-issues` and `gitea-wiki` skills.

## Team
Human, Coordinator, Analyzer, Researcher, Architect, Designer, Developer, Tester, Reviewer, Qa.

## Routing fields
| Field | Where | Meaning | Written by |
|---|---|---|---|
| `to:<Agent>` | label, exactly one | Who acts next. `to:Human` = waiting for the Human | Coordinator sets it. A role agent only swaps it to `to:Coordinator` |
| `Role: <Name>` | body line 1 | Work role of this issue. Never changes | Coordinator |
| `[Agent] <event>` | first line of each comment | Author. No header = Human | Every agent |
| status | issue status | `open`, `in-progress`, `done`, `blocked` | Role agent claims and finishes. Coordinator closes |

New issue from the Human with no `to:` label = Coordinator's.

## Role issue body
```
Role: Developer
Goal: one sentence
Inputs: issue numbers, wiki pages, requirement IDs
Acceptance: checkable criteria
Output: what to deliver, where
```
One issue, one role, one session. Large goals are split into phases by the Coordinator.

## Flow
```
Human --goal--> Coordinator --Role issue--> Analyzer
                     ^                         |
                     |  every role returns     v
                     +---- to:Coordinator <-- Researcher, Architect, Designer,
                                              Developer + Tester, Reviewer, Qa
```
The Coordinator is the hub. Roles never hand to each other and never contact the Human. After each return the Coordinator verifies, then closes or sends the next issue.

| Stage | Agent | Needs | Delivers | Skip when |
|---|---|---|---|---|
| 1 | Analyzer | Human requirements | Wiki `Requirements Review`, findings per severity | Requirements already checked |
| 2 | Researcher | Stated need, constraints | Crate table + recommendation (crates over 10000 downloads) | No new crate needed |
| 3 | Architect | Requirements | Wiki `Domain Model`, ADRs (`proposed`), `Architecture Status` | Design unchanged |
| 4 | Designer | Requirements, users | Wiki `UI Spec - <n>` | No UI |
| 5 | Developer | Requirement IDs, design | Committed code + tests, gate result | Never |
| 5 | Tester | Requirement IDs | Committed tests, remaining gaps | Developer tests cover all IDs |
| 6 | Reviewer | Diff, requirement IDs | Decision: approved or changes requested | Never |
| 7 | Qa | Approved code | Release gate result. On pass: `.rpm`, `.deb`, `SHA256SUMS` in `dist/` | Never |

Developer and Tester may run in parallel as two issues. Reviewer starts after both are `done`.

## One handoff, step by step
1. Coordinator creates the issue: `Role:` line, body template, label `to:<Role>`. Then calls that agent with `Issue #<n>`.
2. Role agent checks line 1 matches its own name. Mismatch: comment `[Agent] misrouted`, status `blocked`, label `to:Coordinator`.
3. It claims (`in-progress`), works in steps, saves state to `.mem/<n>/` and checkpoint comments.
4. It finishes: result comment `[Agent] done`, status `done`, label `to:Coordinator`.
5. Coordinator checks the acceptance criteria. Pass: close, add follow-ups. Fail: rewrite the issue, label `to:<Role>` again.

## Loops
- **Review fails**: Reviewer returns `changes requested`. Coordinator opens a Developer issue with the findings. Then a new Reviewer issue.
- **Defect found by Tester**: Tester reports it. Coordinator opens a Developer issue. Tests are never weakened.
- **Qa gate fails**: no packages. Qa returns `blocked` with evidence. Coordinator opens the fixing issues, then a new Qa issue.
- **Every 3 to 5 finished Developer issues, and before release**: Coordinator runs an architecture checkpoint (Architect issue).

## Blocked and Human
- Any role: unclear, contradictory or missing input: `blocked`, one question, label `to:Coordinator`.
- Coordinator fixes unclear text itself. Critical, irreversible or contradictory: label `to:Human`, one question, 2 to 4 options, a recommendation.
- The Human answers with a comment (no header) and may relabel `to:Coordinator`. Headerless answers on `to:Human` issues are picked up anyway.
- Analyzer `high` finding, an ADR that changes the intended architecture, version and release scope: always go to the Human through the Coordinator.

## Rules for all
- Rust only. No `unwrap`, `expect`, `panic!`, `unsafe` in library code. Crates need 10000+ downloads.
- Touch only issues labeled `to:<you>`. Never change the version or put secrets in text.
- Commit with the issue number. Long results go to the wiki.
- Write "what did you decide that i did not tell you to decide" into the issue comment or wiki.
- Context is 32K tokens: small steps, state outside context, tool output under 1.5K.
