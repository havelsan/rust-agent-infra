---
name: rtk-token-saver
description: "Install and verify RTK so shell output reaches the agent compressed (60 to 90 percent smaller on common commands), and check the savings."
---
Script: `bash .kilo/skills/scripts/rtk_setup.sh` (run with --dry-run first). rtk_setup.sh checks that rtk is installed, proves it keeps the exit code of a failing build, and writes the rtk.ok marker that switches rtk on in the scripts
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
rtk gain shows savings; rtk proxy <cmd> gives raw output. The scripts only use rtk after rtk_setup.sh wrote .kilo/memory/rtk.ok (exit codes verified).
