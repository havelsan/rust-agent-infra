---
description: "[Physics] Model spec with equations, assumptions, units (PO approval)"
agent: team-leader
---
Run `kctx run define-physics-model $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /define-physics-model <phenomenon> [--equations <file>] [--units si] [--validity-range]
Chain: @physicist -> @mathematician -> @business-analyst
Output: Model spec with equations, assumptions, units (PO approval). Product Owner approval at the end.
