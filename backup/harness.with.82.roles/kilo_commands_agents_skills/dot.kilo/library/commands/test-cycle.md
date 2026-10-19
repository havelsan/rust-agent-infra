---
description: "[Core] Test plan, automated suite, defect issues"
agent: team-leader
---
Run `kctx run test-cycle $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /test-cycle <milestone> [--types unit/integration/e2e/regression]
Chain: @software-quality-assurance-engineer -> @software-test-development-engineer -> @software-testing-engineer
Output: Test plan, automated suite, defect issues. Default gates: review, QA, security.
