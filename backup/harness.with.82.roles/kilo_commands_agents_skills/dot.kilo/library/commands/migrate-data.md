---
description: "[Java→Rust] Migration scripts, backfill, reconciliation report"
agent: team-leader
---
Run `kctx run migrate-data $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /migrate-data --source <db-uri> --dest <db-uri> [--mode dual-write/backfill/snapshot] [--verify checksum/row-diff]
Chain: @database-administrator -> @data-engineer -> @backend-developer
Output: Migration scripts, backfill, reconciliation report. Default gates: review, QA, security.
