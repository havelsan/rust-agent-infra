---
description: "[Standards] DDD, clean-code, TDD and design-pattern findings with required fixes"
agent: team-leader
---
Run `kctx run standards-review $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /standards-review [--base <ref>]
Chain: @software-review-engineer -> @software-architect -> @software-quality-assurance-engineer
Output: DDD, clean-code, TDD and design-pattern findings with required fixes. Default gates: review, QA, security.
