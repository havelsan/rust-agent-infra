---
description: "[Physics] Golden-result store with versioned reference data"
agent: team-leader
---
Run `kctx run regression-baseline $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /regression-baseline <sim> [--tolerance-rule abs/rel] [--ref-data <dir>]
Chain: @software-test-development-engineer -> @software-quality-assurance-engineer -> @configuration-manager
Output: Golden-result store with versioned reference data. Default gates: review, QA, security.
