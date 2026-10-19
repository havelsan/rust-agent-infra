---
description: "[Core] Design doc, ADR, threat-model notes"
agent: team-leader
---
Run `kctx run design-feature $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /design-feature <req-id> [--ui yes/no] [--threat-model yes/no]
Chain: @business-analyst -> @system-architect/@software-architect -> @ux-designer -> @security-engineer
Output: Design doc, ADR, threat-model notes. Default gates: review, QA, security.
