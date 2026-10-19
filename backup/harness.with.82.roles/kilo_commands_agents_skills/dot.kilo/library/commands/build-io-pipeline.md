---
description: "[Physics] Scenario input and result output pipeline"
agent: team-leader
---
Run `kctx run build-io-pipeline $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /build-io-pipeline <sim> [--formats hdf5,parquet,json] [--scenario-config toml/yaml]
Chain: @data-engineer -> @backend-developer -> @software-development-engineer
Output: Scenario input and result output pipeline. Default gates: review, QA, security.
