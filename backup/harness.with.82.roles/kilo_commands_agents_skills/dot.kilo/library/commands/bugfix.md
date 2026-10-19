---
description: "[Core] Reproduction, fix, regression test"
agent: team-leader
---
Run `kctx run bugfix $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /bugfix <bug#> [--severity s1..s4] [--regression-test yes/no]
Chain: @software-testing-engineer -> @software-development-engineer -> @software-review-engineer -> @software-quality-assurance-engineer
Output: Reproduction, fix, regression test. Default gates: review, QA, security.
