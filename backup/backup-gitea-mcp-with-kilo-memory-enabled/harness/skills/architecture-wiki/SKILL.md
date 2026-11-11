---
name: architecture-wiki
description: Write the architecture overview, status page, and numbered ADRs in the wiki. Use when recording a design decision or an assessment.
---

# architecture-wiki

Architecture decisions are only useful if the reasons survive. Developers who start with an empty context need to find why the structure is as it is.

## Pages

| Page | Content | Changes |
| --- | --- | --- |
| `Architecture Overview` | Context, layers, crates, main flows, external systems | Only with an accepted ADR |
| `Architecture Status` | Latest assessment: findings and severity | Every checkpoint |
| `ADR-NNN-Title` | One decision with context and consequences | Never edited after acceptance. Superseded by a new ADR |
| `ADR Index` | List of all ADRs with status | With each ADR |

## Procedure for a decision

1. State the problem and the forces (requirements, constraints, principles). Name at least two alternatives and why you did not pick them.
2. Get the number: `wiki_read` `method=list`. Take the highest `ADR-NNN` and add 1. The first ADR is `ADR-001`.
3. Publish the ADR as `proposed` with `wiki_write` `method=create`. Title `ADR-003-Use-In-Process-Channels`, `message` `ADR 003`. Content:

```
# ADR-003: Use in-process channels for events

- Status: proposed
- Date: <date +%F>
- Related issue: #12

## Context
REQ-5 needs low latency; REQ-9 forbids external services.

## Decision
Use bounded channels between application services.

## Consequences
No broker to operate. No multi-process fan-out.

## Alternatives considered
Local MQTT broker: rejected because of REQ-9.
```

4. Update `ADR Index`: `wiki_read get` (page `ADR-Index`), add the line `- [[ADR-003-Use-In-Process-Channels]] - Use in-process channels for events (proposed)`, then `wiki_write` `update`. Create the page with `# ADR Index` when it is missing.
5. Report the ADR page in the issue comment. The Coordinator asks the Human to accept it (`human-escalation`) when the decision is critical.
6. After acceptance, update `Architecture Overview`: read it first (`wiki_read get`), merge, then `wiki_write` `update`.

## Writing rules

- One decision per ADR. Keep it under one screen.
- Use plain, short sentences. Add a diagram only if text cannot show the structure (Mermaid blocks render in Gitea).
- Never rewrite history. Replace an old ADR by a new one that says "Supersedes ADR-003".
- Follow the page rules in `gitea-wiki` (page size, merge before update).

## Steps (split points)

Use with `step-protocol`. One ADR per issue. Steps: draft context and alternatives, publish the ADR, update the index, update the overview page.
