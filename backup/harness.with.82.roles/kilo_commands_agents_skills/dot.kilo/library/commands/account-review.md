---
description: "[Business] Account health, renewal and expansion plan"
agent: team-leader
---
Run `kctx run account-review $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /account-review <customer> [--period] [--renewal-date]
Chain: @account-manager -> @customer-success-manager -> @sales-engineer-solutions-consultant
Output: Account health, renewal and expansion plan. Default gates: review, QA, security.
