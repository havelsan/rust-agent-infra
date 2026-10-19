---
description: "[Quality / Security] Coverage report and missing-test issues"
agent: team-leader
---
Run `kctx run coverage-gap $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /coverage-gap [--tool llvm-cov] [--min 80%]
Chain: @software-quality-assurance-engineer -> @software-test-development-engineer
Output: Coverage report and missing-test issues. Default gates: review, QA, security.
