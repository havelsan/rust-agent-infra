---
description: "[Meta] Conflict resolved and recorded as an ADR"
agent: team-leader
---
Run `kctx run arbitrate-design $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /arbitrate-design <adr#> [--criteria <list>]
Chain: @system-architect -> @software-architect -> @solutions-architect -> @philosopher
Output: Conflict resolved and recorded as an ADR. Default gates: review, QA, security.
