---
description: "[Meta] Blocked issue raised to the Product Owner with options"
agent: team-leader
---
Run `kctx run escalate $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /escalate <issue#> [--options N]
Chain: any -> @team-leader -> @product-owner
Output: Blocked issue raised to the Product Owner with options. Default gates: review, QA, security.
