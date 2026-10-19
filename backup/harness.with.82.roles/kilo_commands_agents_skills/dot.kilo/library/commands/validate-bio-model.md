---
description: "[Domain science] Biological model validation report"
agent: team-leader
---
Run `kctx run validate-bio-model $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /validate-bio-model <model> --against <dataset> [--metric]
Chain: @biologist -> @mathematician -> @software-testing-engineer
Output: Biological model validation report. Default gates: review, QA, security.
