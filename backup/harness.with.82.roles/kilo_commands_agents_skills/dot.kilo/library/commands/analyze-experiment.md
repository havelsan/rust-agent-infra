---
description: "[Data / Analytics] Statistical analysis and recommendation"
agent: team-leader
---
Run `kctx run analyze-experiment $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /analyze-experiment <experiment> [--method ab/bayesian] [--metric]
Chain: @data-scientist -> @data-analyst -> @product-manager
Output: Statistical analysis and recommendation. Default gates: review, QA, security.
