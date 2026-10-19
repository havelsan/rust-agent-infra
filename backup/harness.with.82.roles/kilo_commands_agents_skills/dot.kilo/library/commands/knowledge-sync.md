---
description: "[Meta] Wiki and ADRs updated from merged PRs"
agent: team-leader
---
Run `kctx run knowledge-sync $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /knowledge-sync [--since <tag>] [--targets wiki,adr,api-docs]
Chain: @documentation-engineer -> @internal-tools-engineer
Output: Wiki and ADRs updated from merged PRs. Default gates: review, QA, security.
