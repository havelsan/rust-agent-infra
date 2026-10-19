---
description: "[Java→Rust] Business rules, domain model, ER model (PO approval)"
agent: team-leader
---
Run `kctx run recover-domain $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /recover-domain <module/all> [--from code/db/docs/runtime]
Chain: @business-analyst -> @software-architect -> @database-administrator
Output: Business rules, domain model, ER model (PO approval). Product Owner approval at the end.
