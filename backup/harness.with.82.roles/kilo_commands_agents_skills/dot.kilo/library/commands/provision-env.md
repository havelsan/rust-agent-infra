---
description: "[Infra / Ops] Environment defined as code"
agent: team-leader
---
Run `kctx run provision-env $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /provision-env <env dev/staging/prod> [--cloud <provider>] [--network <topology>]
Chain: @cloud-engineer -> @network-engineer -> @system-administrator -> @cloud-security-engineer
Output: Environment defined as code. Default gates: review, QA, security.
