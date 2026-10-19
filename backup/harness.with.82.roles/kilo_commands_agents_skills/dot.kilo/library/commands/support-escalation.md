---
description: "[Business] Reproduction and bug issue with logs"
agent: team-leader
---
Run `kctx run support-escalation $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /support-escalation <ticket#> [--logs <path>]
Chain: @customer-support-specialist -> @technical-support-engineer -> @software-testing-engineer -> @software-development-engineer
Output: Reproduction and bug issue with logs. Default gates: review, QA, security.
