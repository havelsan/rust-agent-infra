---
name: token-tools-setup
description: "Install and check the four token-saving tools for this project: rtk, graphify, caveman style and ponytail."
---
Script: `bash .kilo/skills/scripts/tools_install.sh` (run with --dry-run first). tools_install.sh shows or with --yes runs the install commands for rtk and graphify, reports caveman and ponytail status, and never installs the caveman skill unless asked
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
Order: rtk, then graphify, then (optional) caveman skill; ponytail is built in. Finish with kctx doctor and report what is missing.
