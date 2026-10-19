---
description: "[Token tools] Token-saving tools installed and verified (kctx doctor report)"
agent: team-leader
---
Run `kctx run setup-token-tools $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /setup-token-tools [--yes] [--only rtk/graphify/caveman/ponytail]
Chain: @platform-engineer -> @devops-engineer -> @internal-tools-engineer
Output: Token-saving tools installed and verified (kctx doctor report). Default gates: review, QA, security.
