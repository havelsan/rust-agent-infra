---
description: "[Token tools] Compressed memory files with before and after token counts"
agent: team-leader
---
Run `kctx run compress-memory $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /compress-memory <file/dir> [--mode lite/full/ultra]
Chain: @documentation-engineer -> @internal-tools-engineer
Output: Compressed memory files with before and after token counts. Default gates: review, QA, security.
