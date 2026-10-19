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
| `ADR Index` | List of all ADRs with status | Automatically with each ADR |

## Procedure for a decision

1. State the problem and the forces (requirements, constraints, principles). Name at least two alternatives and why you did not pick them.
2. Publish the ADR as `proposed`:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/architecture-wiki/scripts/publish_adr.py \
  --title "Use in-process channels for events" \
  --context "REQ-5 needs low latency; REQ-9 forbids external services." \
  --decision "Use bounded channels between application services." \
  --consequences "No broker to operate. No multi-process fan-out." \
  --alternatives "Local MQTT broker: rejected because of REQ-9." \
  --issue 12 --dry-run
```

Remove `--dry-run` to publish.
3. Report the ADR page in the issue comment. The Coordinator asks the Human to accept it (`human-escalation`) when the decision is critical.
4. After acceptance, update `Architecture Overview` (read it first with `gitea-wiki get`, merge, then `put`).

## Writing rules

- One decision per ADR. Keep it under one screen.
- Use plain, short sentences. Add a diagram only if text cannot show the structure (Mermaid blocks render in Gitea).
- Never rewrite history. Replace an old ADR by a new one that says "Supersedes ADR-003".

## Steps (split points)

Use with `step-protocol`. One ADR per issue. Steps: draft context and alternatives, publish with `--dry-run`, publish, update the overview page.
