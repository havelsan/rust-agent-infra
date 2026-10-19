---
description: "[Infra / Ops] Reviewed migration with backup and rollback"
agent: team-leader
---
Run `kctx run db-change $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /db-change <migration> [--type schema/index/backup/permission] [--online yes/no]
Chain: @database-administrator -> @backend-developer -> @software-quality-assurance-engineer
Output: Reviewed migration with backup and rollback. Default gates: review, QA, security.
