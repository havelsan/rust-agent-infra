---
description: "[Data / Analytics] Metric definitions and transformation models"
agent: team-leader
---
Run `kctx run define-metrics $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /define-metrics <domain> [--layer raw/staging/mart] [--engine polars/datafusion]
Chain: @analytics-engineer -> @data-engineer -> @data-analyst
Output: Metric definitions and transformation models. Default gates: review, QA, security.
