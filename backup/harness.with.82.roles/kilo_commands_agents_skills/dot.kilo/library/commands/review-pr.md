---
description: "[Core] Review verdict, blockers filed as issues"
agent: team-leader
---
Run `kctx run review-pr $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /review-pr <pr#> [--focus arch/style/security/perf]
Chain: @software-review-engineer -> @application-security-engineer -> @performance-engineer
Output: Review verdict, blockers filed as issues. Default gates: review, QA, security.
