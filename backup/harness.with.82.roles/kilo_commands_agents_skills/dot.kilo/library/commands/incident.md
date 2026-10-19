---
description: "[Infra / Ops] Triage, mitigation, communication"
agent: team-leader
---
Run `kctx run incident $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /incident <alert/issue> [--severity sev1..sev4] [--comms-channel]
Chain: @incident-manager -> @site-reliability-engineer -> @software-development-engineer -> @technical-support-engineer
Output: Triage, mitigation, communication. Default gates: review, QA, security.
