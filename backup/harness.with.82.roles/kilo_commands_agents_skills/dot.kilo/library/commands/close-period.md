---
description: "[Business] Reconciliation, financial report, cost allocation"
agent: team-leader
---
Run `kctx run close-period $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /close-period <month/quarter> [--allocate cloud,compute]
Chain: @accountant -> @financial-analyst -> @finance-manager-cfo
Output: Reconciliation, financial report, cost allocation. Default gates: review, QA, security.
