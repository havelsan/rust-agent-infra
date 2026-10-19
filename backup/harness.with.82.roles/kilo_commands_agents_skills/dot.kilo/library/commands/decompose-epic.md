---
description: "[Core] Child issues with owners, estimates, dependencies"
agent: team-leader
---
Run `kctx run decompose-epic $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /decompose-epic <epic#> [--max-issues] [--granularity story/task]
Chain: @team-leader -> @software-architect -> @project-manager
Output: Child issues with owners, estimates, dependencies. Default gates: review, QA, security.
