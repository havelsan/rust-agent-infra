---
description: "[Core] Roadmap, milestones, dependency map, risk register (PO approval)"
agent: team-leader
---
Run `kctx run plan-roadmap $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /plan-roadmap [--horizon quarter/year] [--themes] [--capacity]
Chain: @product-manager -> @business-analyst -> @project-manager -> @financial-analyst
Output: Roadmap, milestones, dependency map, risk register (PO approval). Product Owner approval at the end.
