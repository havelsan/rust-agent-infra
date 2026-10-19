---
description: "[Java→Rust] User journeys, pain points, cognitive-load findings"
agent: team-leader
---
Run `kctx run ux-audit-legacy $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /ux-audit-legacy <app> [--journeys <list>] [--personas]
Chain: @ux-researcher -> @psychologist -> @ux-designer -> @business-analyst
Output: User journeys, pain points, cognitive-load findings. Default gates: review, QA, security.
