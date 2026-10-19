---
description: "[Quality / Security] Soundness review of every unsafe block"
agent: team-leader
---
Run `kctx run unsafe-audit $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /unsafe-audit <crate> [--tools miri,cargo-geiger]
Chain: @application-security-engineer -> @software-review-engineer -> @computer-hardware-engineer
Output: Soundness review of every `unsafe` block. Default gates: review, QA, security.
