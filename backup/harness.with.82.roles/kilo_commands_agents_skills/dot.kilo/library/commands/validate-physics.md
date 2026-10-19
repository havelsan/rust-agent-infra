---
description: "[Physics] Validation report (PO approval)"
agent: team-leader
---
Run `kctx run validate-physics $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /validate-physics --against <dataset/analytic/paper> [--metric l2/linf/energy-drift] [--threshold 1e-3] [--experts 51,54,55,56]
Chain: @physicist -> @mechanical-engineer/@civil-engineer/@electronics-engineer/@chemist -> @software-testing-engineer
Output: Validation report (PO approval). Product Owner approval at the end.
