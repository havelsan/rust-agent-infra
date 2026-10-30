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
3. Post this comment with `issue_write` `add_comment` (normal style, no terse mode):

```
[Coordinator] question

**Decision needed from Human**

**Question:** Which message bus should project-01 use?
**Why it matters:** REQ-5 says low latency; REQ-9 says no external services.
**Options:**
- **A**: In-process channel (no external service)
- **B**: Local MQTT broker
**Recommendation:** option A, because REQ-9 forbids external services.

Reply with a comment on this issue. The work is paused until then.
```

4. Hand the issue to the Human: `replace_labels` with `to:Human` and `status:blocked`, other labels unchanged.
5. Stop work on that issue. Continue other issues that do not depend on the answer.
6. The Human answers with a plain comment (no `[Agent]` header). A newest comment without a header on a `to:Human` issue is the answer. Relabel to `to:Coordinator` and `status:in-progress`, record the decision in the wiki if it affects later work, and continue.
