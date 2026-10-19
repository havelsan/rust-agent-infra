---
description: "[Core] Code, unit tests, PR"
agent: team-leader
---
Run `kctx run implement-task $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /implement-task <issue#> [--role sde/be/fe/desktop] [--tests unit/unit+integration]
Chain: @software-development-engineer/@backend-developer/@frontend-developer/@desktop-developer -> @software-test-development-engineer
Output: Code, unit tests, PR. Default gates: review, QA, security.
