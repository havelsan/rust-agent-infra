---
description: "[Business] Insights feeding the next /plan-roadmap"
agent: team-leader
---
Run `kctx run feedback-loop $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /feedback-loop [--sources tickets,surveys,usage] [--period]
Chain: @customer-success-manager -> @data-analyst -> @ux-researcher -> @product-manager
Output: Insights feeding the next `/plan-roadmap`. Default gates: review, QA, security.
