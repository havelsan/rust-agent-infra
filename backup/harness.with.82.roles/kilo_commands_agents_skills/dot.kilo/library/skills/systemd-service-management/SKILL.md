---
name: systemd-service-management
description: "Package and run Rust services under systemd with sandboxing, restarts and resource limits."
---
Script: `bash .kilo/skills/scripts/gen_unit.sh` (run with --dry-run first). gen_unit.sh generates a hardened unit file and validates it with systemd-analyze verify
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
