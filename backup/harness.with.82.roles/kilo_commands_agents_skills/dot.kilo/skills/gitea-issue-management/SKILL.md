---
name: gitea-issue-management
description: "Create, comment on, label, assign, link and close Gitea issues using the project label scheme (role:N, phase:x, gate:y). Gitea issues are the only communication channel between agents."
---
Script: `bash .kilo/skills/scripts/gitea_issue.sh` (run with --dry-run first). gitea_issue.sh wraps the Gitea REST API (create, comment, label, assign, close, list); reads the token from env and prints the issue JSON
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
