---
description: "[AI / ML] Safety review and mitigation issues"
agent: team-leader
---
Run `kctx run ai-safety-review $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /ai-safety-review <feature> [--risks misuse,leakage,bias]
Chain: @security-engineer -> @philosopher -> @ai-engineer
Output: Safety review and mitigation issues. Default gates: review, QA, security.
