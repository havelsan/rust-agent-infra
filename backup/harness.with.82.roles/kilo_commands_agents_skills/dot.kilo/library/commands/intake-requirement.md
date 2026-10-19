---
description: "[Core] Requirement doc, acceptance criteria, traceability IDs (PO approval)"
agent: team-leader
---
Run `kctx run intake-requirement $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /intake-requirement <title> [--source po/customer/support] [--req-id]
Chain: @product-owner -> @business-analyst -> @product-manager -> @team-leader
Output: Requirement doc, acceptance criteria, traceability IDs (PO approval). Product Owner approval at the end.
