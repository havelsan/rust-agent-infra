---
description: "[IT] Policy, asset, and access review"
agent: team-leader
---
Run `kctx run it-policy-review $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /it-policy-review [--areas access,assets,policies]
Chain: @it-manager -> @security-engineer -> @compliance-engineer -> @configuration-manager
Output: Policy, asset, and access review. Default gates: review, QA, security.
