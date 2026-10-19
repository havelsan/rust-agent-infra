---
description: "[Token tools] Unused and duplicate dependencies, over-built code, removal plan"
agent: team-leader
---
Run `kctx run ponytail-audit $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /ponytail-audit [--scope crate/workspace]
Chain: @software-review-engineer -> @application-security-engineer -> @devops-engineer
Output: Unused and duplicate dependencies, over-built code, removal plan. Default gates: review, QA, security.
