---
description: "[Infra / Ops] SLIs, SLOs, dashboards, alerts"
agent: team-leader
---
Run `kctx run define-slo $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /define-slo <service> [--slis latency,availability,error-rate] [--targets]
Chain: @site-reliability-engineer -> @product-manager -> @project-manager
Output: SLIs, SLOs, dashboards, alerts. Default gates: review, QA, security.
