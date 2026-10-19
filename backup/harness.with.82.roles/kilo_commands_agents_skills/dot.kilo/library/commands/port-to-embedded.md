---
description: "[Mobile / Embedded] Library ported to a constrained device"
agent: team-leader
---
Run `kctx run port-to-embedded $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /port-to-embedded <crate> --target <triple> [--no-std] [--mem-budget]
Chain: @embedded-systems-engineer -> @software-development-engineer -> @performance-engineer
Output: Library ported to a constrained device. Default gates: review, QA, security.
