---
description: "[Physics] Workspace with crate skeletons and a units layer"
agent: team-leader
---
Run `kctx run scaffold-workspace $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /scaffold-workspace <project> [--crates core-math,physics,solver,io,viz,cli] [--units uom/nalgebra]
Chain: @software-development-engineer -> @platform-engineer -> @devops-engineer
Output: Workspace with crate skeletons and a units layer. Default gates: review, QA, security.
