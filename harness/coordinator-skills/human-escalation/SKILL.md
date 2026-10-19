---
name: human-escalation
description: Ask the Human a decision question through a blocked issue with options and a recommendation. Use for unclear, critical, or conflicting decisions.
---

# human-escalation

The Human decides every critical question, and only through Gitea issues. The Human's attention is limited, so a good escalation can be answered with one short reply.

## When to escalate

- The goal, scope, or acceptance criteria are unclear or contradict each other.
- A choice changes cost, safety, schedule, licensing, or architecture and cannot be undone easily.
- Two agents disagree and the evidence does not settle it.
- Required access, credentials, or data are missing.

Do not escalate what the project documents already answer, or small choices inside the Coordinator's role. Decide those, and record the reason in a comment.

## Procedure

1. Try to resolve the question first: read the issue history and wiki, and ask the Analyzer role to check requirements if the cause may be a contradiction.
2. Reduce the question to one decision. Offer two to four options and give a recommendation with the reason.
3. Send it:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/coordinator-skills/human-escalation/scripts/escalate.py 12 \
  --question "Which message bus should project-01 use?" \
  --context "Requirement REQ-5 says low latency; REQ-9 says no external services." \
  --option "In-process channel (no external service)" \
  --option "Local MQTT broker" \
  --recommend A
```

The script posts the comment, sets `status:blocked`, and assigns the issue to `$HUMAN_USER`.

4. Stop work on that issue. Continue other issues that do not depend on the answer.
5. When the Human replies and assigns the issue back, record the decision in the wiki if it affects later work, set `status:in-progress`, and continue.
