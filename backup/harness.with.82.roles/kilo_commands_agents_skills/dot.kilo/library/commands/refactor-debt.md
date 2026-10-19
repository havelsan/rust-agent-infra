---
description: "[Core] Debt report, refactor PRs, behavior-unchanged proof"
agent: team-leader
---
Run `kctx run refactor-debt $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /refactor-debt <crate/module> [--goal readability/perf/modularity] [--behavior-lock yes]
Chain: @software-review-engineer -> @software-architect -> @software-development-engineer -> @software-quality-assurance-engineer
Output: Debt report, refactor PRs, behavior-unchanged proof. Default gates: review, QA, security.
