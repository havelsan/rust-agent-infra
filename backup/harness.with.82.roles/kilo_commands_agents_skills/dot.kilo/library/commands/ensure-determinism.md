---
description: "[Physics] Reproducibility tests and floating-point policy"
agent: team-leader
---
Run `kctx run ensure-determinism $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /ensure-determinism <module> [--across threads,platforms,builds] [--fp-policy strict/relaxed]
Chain: @software-development-engineer -> @performance-engineer -> @software-test-development-engineer
Output: Reproducibility tests and floating-point policy. Default gates: review, QA, security.
