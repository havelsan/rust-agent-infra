---
description: "[IT] Workstation setup, access, toolchain"
agent: team-leader
---
Run `kctx run onboard-employee-env $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /onboard-employee-env <person/team> [--toolchain rust,git,docker] [--access <groups>]
Chain: @it-support-engineer -> @system-administrator -> @internal-tools-engineer
Output: Workstation setup, access, toolchain. Default gates: review, QA, security.
