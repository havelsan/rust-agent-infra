---
description: "[Physics] Convergence-order and conservation test suite"
agent: team-leader
---
Run `kctx run verify-numerics $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /verify-numerics <module> [--tests mms,convergence,conservation,property] [--order <expected>]
Chain: @mathematician -> @software-test-development-engineer -> @software-quality-assurance-engineer
Output: Convergence-order and conservation test suite. Default gates: review, QA, security.
