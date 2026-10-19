---
name: supply-chain-audit
description: "Audit dependencies for vulnerabilities, licenses and provenance."
---
Script: `bash .kilo/skills/scripts/deps_audit.sh` (run with --dry-run first). deps_audit.sh runs cargo audit, cargo deny and SBOM generation and outputs advisories and license violations
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
