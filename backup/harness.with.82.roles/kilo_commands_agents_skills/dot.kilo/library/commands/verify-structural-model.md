---
description: "[Physics] Structural model verification"
agent: team-leader
---
Run `kctx run verify-structural-model $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /verify-structural-model <model> [--loads static/dynamic] [--code <standard>]
Chain: @civil-engineer -> @mathematician -> @physicist
Output: Structural model verification. Default gates: review, QA, security.
