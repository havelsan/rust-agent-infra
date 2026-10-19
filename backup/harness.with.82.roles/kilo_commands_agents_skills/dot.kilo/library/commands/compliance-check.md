---
description: "[Business] Control mapping and audit evidence"
agent: team-leader
---
Run `kctx run compliance-check $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /compliance-check <standard> [--controls <list>] [--evidence-dir <path>]
Chain: @compliance-engineer -> @legal-counsel -> @security-engineer -> @documentation-engineer
Output: Control mapping and audit evidence. Default gates: review, QA, security.
