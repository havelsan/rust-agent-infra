---
description: "[Core] Tagged release, changelog, signed artifacts (PO approval)"
agent: team-leader
---
Run `kctx run release $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /release --version <semver> [--channel stable/rc/nightly] [--rollout canary:N%/full] [--rollback-on slo-breach]
Chain: @release-manager -> @devops-engineer -> @configuration-manager -> @documentation-engineer -> @technical-writer
Output: Tagged release, changelog, signed artifacts (PO approval). Product Owner approval at the end.
