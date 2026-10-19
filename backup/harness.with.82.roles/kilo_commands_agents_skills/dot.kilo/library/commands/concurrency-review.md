---
description: "[Quality / Security] Race and deadlock review, loom tests"
agent: team-leader
---
Run `kctx run concurrency-review $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /concurrency-review <crate> [--tools loom] [--focus deadlock/race]
Chain: @software-architect -> @software-review-engineer -> @software-development-engineer
Output: Race and deadlock review, loom tests. Default gates: review, QA, security.
