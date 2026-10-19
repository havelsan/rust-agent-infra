---
description: "[Quality / Security] Findings and fix plan"
agent: team-leader
---
Run `kctx run pen-test $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /pen-test <service> [--scope external/internal] [--rules-of-engagement]
Chain: @cybersecurity-analyst -> @security-engineer -> @security-operations-engineer
Output: Findings and fix plan. Default gates: review, QA, security.
