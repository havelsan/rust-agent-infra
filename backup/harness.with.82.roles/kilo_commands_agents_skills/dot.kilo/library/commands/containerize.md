---
description: "[Infra / Ops] Minimal reproducible images"
agent: team-leader
---
Run `kctx run containerize $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /containerize <service> [--base distroless/scratch/ubuntu] [--static yes/no]
Chain: @devops-engineer -> @system-administrator -> @platform-engineer
Output: Minimal reproducible images. Default gates: review, QA, security.
