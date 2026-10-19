---
description: "[Domain science] Clinical terminology and safety-threshold check"
agent: team-leader
---
Run `kctx run clinical-safety-review $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /clinical-safety-review <feature> [--guideline <ref>] [--thresholds]
Chain: @medical-doctor -> @compliance-engineer -> @security-engineer
Output: Clinical terminology and safety-threshold check. Default gates: review, QA, security.
