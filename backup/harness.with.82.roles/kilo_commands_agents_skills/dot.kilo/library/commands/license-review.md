---
description: "[Business] License compatibility report"
agent: team-leader
---
Run `kctx run license-review $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /license-review [--policy <file>] [--include-transitive]
Chain: @legal-counsel -> @application-security-engineer
Output: License compatibility report. Default gates: review, QA, security.
