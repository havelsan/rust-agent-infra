---
description: "[Physics] Theory manual, API docs, validation report, tutorials"
agent: team-leader
---
Run `kctx run document-model $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /document-model <sim> [--parts theory,api,validation,tutorial]
Chain: @documentation-engineer -> @technical-writer -> @physicist
Output: Theory manual, API docs, validation report, tutorials. Default gates: review, QA, security.
