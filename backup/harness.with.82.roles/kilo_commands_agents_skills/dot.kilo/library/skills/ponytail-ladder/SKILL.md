---
name: ponytail-ladder
description: "Before writing new code, climb the simplest-solution ladder: skip it, std, platform feature, existing dependency, one expression, else minimum code. Never skip correctness or security."
---
Script: `bash .kilo/skills/scripts/ponytail_audit.sh` (run with --dry-run first). ponytail_audit.sh finds unused dependencies (cargo machete), duplicate dependency versions (cargo tree --duplicates), and the largest source files to spot over-building
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
Ladder, stop at the first yes: 1 needed at all? skip. 2 std/core covers it? use. 3 platform or framework feature? use. 4 dependency already in Cargo.lock? use. 5 one expression (iterator, `?`, derive)? write it. 6 else minimum custom code.
Never skip: correctness, security, validation at trust boundaries, data-loss handling, accessibility. Mark decisions `// ponytail: <why>`. Check bloat with cargo tree -d and cargo machete.
